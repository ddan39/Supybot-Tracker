###
# Copyright (c) 2014-2016
# All rights reserved.
#
#
###

import supybot.utils as utils
from supybot.commands import *
import supybot.plugins as plugins
import supybot.schedule as schedule
import supybot.ircutils as ircutils
import supybot.callbacks as callbacks

# standard library
import re
import uuid
import time
import pprint
import os.path
import traceback
import xmlrpclib
import threading
import unicodedata
from datetime import datetime, timedelta
from contextlib import closing
from urllib import urlencode, quote
from binascii import hexlify, unhexlify

# system packages 
import mysql.connector
import libtorrent as lt

# included
import ocelot

cat_ids = {'Misc':0}

cat_names = dict(zip(cat_ids.values(), cat_ids.keys()))

tracker_url = 'http://tracker.somesite.com:12345' # assumes tracker users /PASSKEY/announce format
bot_passkey = '' # passkey the bot's libtorrent client will use
chan = '#share'

def getdb():
    return mysql.connector.connect(database='', host='127.0.0.1', port=3306, user='root', password='')

def sqltime():
    return datetime.now().strftime('%F %T')

def sizefmt(num, suffix='B'):
    for unit in ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi']:
        if abs(num) < 1024.0:
            return "%3.1f %s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s %s" % (num, 'Yi', suffix)

def timefmt(seconds, level=1):
    seconds = int(seconds)
    parts = []
    for unit, i in (('yr', 31556926), ('mo', 2629744), ('wk', 604800), ('d', 86400), ('hr', 3600), ('min', 60)):
        num = seconds / i
        if num:
            seconds = seconds - num * i
            parts.append('%s%s' % (num, unit))
    if seconds:
        parts.append('%ss' % seconds)
    if parts:
        return ' '.join(parts[:level]) + ' ago'
    else:
        return 'Just now'

def is_infohash(s):
    return len(s) == 40 and all(c in '0123456789abcdefABCDEF' for c in s)

# ported from gazelle php
# TODO: junk this for sphinx search
def build_search(searchstr, field, exact=False, sqlwhere='', fulltext=0):
    """returns (sql where string, data tuple)"""
    addwhere = False if sqlwhere else True

    data = []

    if not exact:
        if fulltext and re.search('[^a-zA-z0-9 ]', searchstr, flags=re.I):
            fulltext=0

        searchstr = ' '.join(searchstr.split())
        searchstr = re.sub('"([^"]*?)"', lambda x: x.group(1).strip().replace(' ', '{{SPACE}}'), searchstr)
        searchstr = searchstr.split()

        for searchval in searchstr:
            searchval.replace('{{SPACE}}', ' ')

            if fulltext and len(searchval) > 2:
                if sqlwhere:
                    sqlwhere += ' AND '
                if searchval[0] == '-':
                    sqlwhere += 'MATCH (%s) AGAINST (%%s IN BOOLEAN MODE)' % field
                else:
                    sqlwhere += 'MATCH (%s) AGAINST (%%s)' % field
                data.append(searchval)
            else:
                if sqlwhere:
                    sqlwhere += ' AND '
                if searchval[0] == '-':
                    sqlwhere += '%s NOT LIKE %%s' % field
                    data.append('%'+searchval[1:]+'%')
                else:
                    sqlwhere += '%s LIKE %%s' % field
                    data.append('%'+searchval+'%')
    else:
        if sqlwhere:
            sqlwhere += ' AND '
        sqlwhere += '%s = %%s' % field
        data.append(searchstr.strip())

    if sqlwhere and addwhere:
        sqlwhere = 'WHERE %s' % sqlwhere
    
    return (sqlwhere, tuple(data))


class Tracker(callbacks.Plugin):
    """Allows irc users to communicate with and upload torrents
    to bittorrent tracker backend"""

    def __init__(self, irc):
        self.__parent = super(Tracker, self)
        self.__parent.__init__(irc)
        self.irc = irc

        self._tracker = ocelot.Ocelot()
        self.anopexmlrpc = xmlrpclib.ServerProxy('http://127.0.0.1:8080/xmlrpc')

    def _getuser(self, irc, msg, db, cur):
        """gets anope nickserv account, checks if the account is in tracker db,
        if not it runs _register() for new one. then returns dictionary of user's info"""
        nickinfo = self.anopexmlrpc.user(msg.nick)

        if 'account' not in nickinfo:
            irc.error('You are not registered/identified with nickserv')
            return None

        account = nickinfo['account']
        cur.execute('SELECT ID, IP FROM users_main WHERE Username = %s', (account,))
        res = cur.fetchone()
        if res:
            userid = res[0]
            if res[1] != nickinfo['ip']:
                cur.execute('''UPDATE users_history_ips SET EndTime = %s
                            WHERE EndTime IS NULL
                                AND UserID = %s
                                AND IP = %s''',
                            (sqltime(), userid, res[1]))
                cur.execute('''INSERT IGNORE INTO users_history_ips
                                (UserID, IP, StartTime) VALUES (%s,%s,%s)''',
                                (userid, nickinfo['ip'], sqltime()))
                cur.execute('UPDATE users_main SET IP = %s WHERE ID = %s', (nickinfo['ip'], userid))
                db.commit()
        else:
            userid = self._register(account, nickinfo['ip'], db, cur)

        cur.execute('UPDATE users_main SET LastAccess = %s WHERE ID = %s', (sqltime(), userid))
        db.commit()

        cur.execute('''SELECT m.ID, m.Username, m.Uploaded, m.Downloaded, m.torrent_pass,
                            m.Paranoia, m.can_leech, m.Enabled, i.Warned, i.CatchupTime,
                            i.DisableUpload, i.DisableRequests, i.SiteOptions
                    FROM users_main AS m
                        INNER JOIN users_info As i ON i.UserID = m.ID
                    WHERE m.ID = %s
                    GROUP BY m.ID''', (userid,))

        return dict(zip(cur.column_names, cur.fetchone()))

    def _register(self, account, ip, db, cur):
        """Register a new user into db and send update to tracker"""

        passkey = uuid.uuid4().hex # generates a 32 character random hex string

        cur.execute('''INSERT INTO users_main (Username, torrent_pass, IP, PermissionID, Enabled, Invites, Uploaded)
                VALUES (%s,%s,%s,%s,%s,%s,%s)''',
                (account, passkey, ip, '2', '1', '0', '0'))

        userid = cur.lastrowid

        cur.execute('INSERT INTO users_info (UserID, JoinDate) VALUES (%s,%s)', (userid, sqltime()))
        cur.execute('INSERT INTO users_history_ips (UserID, IP, StartTime) VALUES (%s,%s,%s)', (userid, ip, sqltime()))
        db.commit()
        
        self._tracker.update_tracker('add_user', {'id': userid, 'passkey': passkey});    

        return userid

    def _expiretorrents(self, irc):
        now = time.time()
        for tor in self.ltses.get_torrents():
            status = tor.status()
            if not status.has_metadata and now - status.added_time > 1800:
                name = tor.name()
                self.ltses.remove_torrent(tor)
                self.log.error('30min timeout %s %s %s' % (name, status.info_hash, status.has_metadata))
                irc.reply('Removed %s from client. 30 minutes and no metadata :(' % name, prefixNick=False, to=chan)

    def _checkmetadata(self, irc):
        """check alerts from libtorrent session for torrents that have received metadata,
        gets the torrent's info and inserts into tracker db, and outputs to channel"""
        try:
            for alert in self.ltses.pop_alerts():
                print alert.message()
                if isinstance(alert, lt.metadata_received_alert):
                    ti = alert.handle.get_torrent_info()
                    infohash = ti.info_hash().to_bytes()
                    tfile = lt.create_torrent(ti).generate()
                    tfile['announce'] = '%s/passkey/announce' % tracker_url

                    filestring = []
                    if 'files' in tfile['info']:
                        for f in tfile['info']['files']:
                            name = os.path.join(*f['path']).decode('utf-8')
                            ext = os.path.splitext(name)[1][1:].decode('utf-8')
                            filestring.append(u'%s s%ss %s \xf7' % (ext, f['length'], name))
                    else:
                        name = tfile['info']['name'].decode('utf-8')
                        ext = os.path.splitext(name)[1][1:].decode('utf-8')
                        filestring.append(u'%s s%ss %s \xf7' % (ext, tfile['info']['length'], name))
                    filestring = '\n'.join(filestring)

                    with closing(getdb()) as db, closing(db.cursor()) as cur:
                        cur.execute('SELECT ID FROM torrents WHERE info_hash = %s', (infohash,))
                        tid = cur.fetchone()[0]

                        cur.execute('UPDATE torrents SET FileCount = %s, FileList = %s, FilePath = %s, Size = %s WHERE info_hash = %s',
                                (ti.num_files(), filestring, ti.name() if 'files' in tfile['info'] else '', ti.total_size(), infohash))

                        cur.execute('INSERT IGNORE INTO torrents_files (TorrentID, File) VALUES (%s, %s)', (tid, lt.bencode(tfile)))
                        db.commit()

                    #self.ltses.remove_torrent(alert.handle)

                    irc.reply('%s got metadata: %s | %s files | Size: %s' % (tid, ti.name(), ti.num_files(), sizefmt(ti.total_size())), prefixNick=False, to=chan)
        except:
            traceback.print_exc()

    def _output_torrents(self, irc, result, page):
        # format each field of torrent into it's finaly string
        for i, t in enumerate(result):
            result[i] = list(t)
            result[i][1] = cat_names[result[i][1]]
            if len(t[2]) > 60:
                result[i][2] = t[2][:58] + '..'
            result[i][3] = timefmt((datetime.now() - t[3]).total_seconds())
            result[i][4] = sizefmt(t[4])
            result[i][6] = 'Yes' if t[6] == '1' else 'No'
            result[i] = map(unicode, result[i])

        # calculate width for each field
        m = []
        for field in zip(*result):
            m.append(max(len(x) for x in field))

        # make sure widths are wide enough to fit the column header tags
        m[1] = max(m[1], 3)
        m[2] = max(m[2], 4)
        m[3] = max(m[3], 4)
        m[4] = max(m[4], 4)
        m[5] = max(m[5], 5)
        m[6] = max(m[6], 5)

        # send header, with each column tag centered in width
        l = zip((page, 'Cat', 'Name', 'Time', 'Size', 'Files', 'Scene', u'\u2714', u'\u25b2', u'\u25bc'), m)
        header = tuple(item for sublist in l for item in sublist)
        irc.reply(u'Pg {:>{}}  {:^{}} | {:^{}} | {:^{}} | {:^{}} | {:^{}} | {:^{}} | {:^{}} | {:^{}} | {:^{}}'.format(*header),
                prefixNick=False, sendImmediately=True)
        
        # send torrents
        for torrent in reversed(result):
            l = zip(torrent, m)
            torrent = tuple(item for sublist in l for item in sublist)
            irc.reply(u'dl {:>{}}: {:^{}} | {:{}} | {:^{}} | {:^{}} | {:^{}} | {:^{}} | {:^{}} | {:^{}} | {:^{}}'.format(*torrent),
                    prefixNick=False, sendImmediately=True)

    @wrap(['owner'])
    def ltstart(self, irc, msg, args):
        """Start the libtorrent session and schedules"""
        if hasattr(self, 'ltses'):
            irc.error('Already running')
            return

        settings = lt.session_settings()
        settings.user_agent = 'ShareBot/1.3'
        settings.rate_limit_ip_overhead = False

        self.ltses = lt.session(flags=0)
        self.ltses.add_extension('ut_metadata')
        self.ltses.add_extension('metadata_transfer')
        self.ltses.set_settings(settings)
        self.ltses.listen_on(27622, 27632)

        self.ltses.set_alert_mask(lt.alert.category_t.status_notification)

        schedule.addPeriodicEvent(self._checkmetadata, 2, 'checkmetadata', False, args=[irc])
        schedule.addPeriodicEvent(self._expiretorrents, 300, 'expiretorrents', False, args=[irc])

        irc.replySuccess()

    @wrap(['owner'])
    def ltstop(self, irc, msg, args):
        """Stop the bittorrent libtorrent session and schedules"""
        if not hasattr(self, 'ltses'):
            irc.error('Doesnt seem to be running')
            return

        del self.ltses
        schedule.removeEvent('checkmetadata')
        schedule.removeEvent('expiretorrents')
        irc.replySuccess()

    @wrap(['owner', 'text'])
    def ltretry(self, irc, msg, args, tids):
        """Adds the torrent into libtorrent to try getting metadata"""
        if not hasattr(self, 'ltses'):
            irc.error('no libtorrent session')
            return
        with closing(getdb()) as db, closing(db.cursor()) as cur:
            tids = tids.split()
            for tid in tids:
                if not re.match('^([0-9]+|[0-9]+-[0-9]+)$', tid):
                    irc.error('invalid id %s' % tid)
                    continue
                if '-' in tid:
                    start,stop = map(int, tid.split('-'))
                else:
                    start = stop = int(tid)
                for i in xrange(start, stop+1):
                    cur.execute('SELECT Name, info_hash FROM torrents WHERE ID = %s', (i,))
                    result = cur.fetchone()
                    if not result:
                        irc.error('%s doesnt exist, skipping' % i)
                        continue
                    name, infohash = result
                    print repr(name)
                    params = {'ti': None,
                            'name': name.encode('utf-8'),
                            'flags': 516, # upload_mode and update_subscribe
                            'trackers': ['%s/%s/announce' % (tracker_url, bot_passkey)],
                            'info_hash': str(infohash),
                            'save_path': 'tmp/',
                            'storage_mode': lt.storage_mode_t(2)}
                    self.ltses.add_torrent(params)
                    irc.reply('Added %s' % name, prefixNick=False)
        irc.replySuccess()

    @wrap(['owner', 'text'])
    def ltrm(self, irc, msg ,args, tids):
        """Removes the torrent from libtorrent"""
        if not hasattr(self, 'ltses'):
            irc.error('no libtorrent session')
            return
        with closing(getdb()) as db, closing(db.cursor()) as cur:
            tids = tids.split()
            for tid in tids:
                if not re.match('^([0-9]+|[0-9]+-[0-9]+)$', tid):
                    irc.error('invalid id %s' % tid)
                    continue
                if '-' in tid:
                    start,stop = map(int, tid.split('-'))
                else:
                    start = stop = int(tid)
                for i in xrange(start, stop+1):
                    cur.execute('SELECT Name, info_hash FROM torrents WHERE ID = %s', (i,))
                    result = cur.fetchone()
                    if not result:
                        irc.error('%s doesnt exist' % tids)
                        return
                    name, infohash = result
                    infohash = lt.big_number(str(infohash))
                    handle = self.ltses.find_torrent(infohash)
                    if handle.is_valid():
                        self.ltses.remove_torrent(handle)
                    else:
                        irc.error('%s not found in lt' % i)

    @wrap
    def ltstats(self, irc, msg, args):
        """Reports some stats about running libtorrent session"""
        if not hasattr(self, 'ltses'):
            irc.error('no libtorrent session')
            return
        tors = self.ltses.get_torrents()
        numtors = len(tors)
        tornames = ', '.join(x.name() for x in tors)
        irc.reply('%s torrent%s: %s' % (len(tors), '' if numtors == 1 else 's', tornames), prefixNick=False)

    @wrap(['text'])
    def lttorstats(self, irc, msg, args, name):
        """Reports some stats about a specific torrent in libtorrent"""
        if not hasattr(self, 'ltses'):
            irc.error('no libtorrent session')
            return
        if is_infohash(name):
            tor = self.ltses.find_torrent(name)
            if not tor.is_valid():
                irc.error('Not found')
                return
        else:
            tors = self.ltses.get_torrents()
            for tor in tors:
                if tor.name() == name: break
        s = tor.status()
        active = str(timedelta(seconds=s.active_time))
        irc.reply('%s | state: %s active time: %s has metadata: %s total dl: %s next announce: %s connected peers: %s connected seeds: %s total peers: %s total seeds: %s error: %s' %
                (tor.name(), s.state, active, s.has_metadata, s.total_download, s.next_announce, s.num_peers, s.num_seeds, s.list_peers, s.list_seeds, s.error), prefixNick=False)

    @wrap([optional('somethingWithoutSpaces')])
    def stats(self, irc, msg, args, username):
        """Get ul/dl stats from tracker db"""
        with closing(getdb()) as db, closing(db.cursor()) as cur:
            if username is not None:
                msg.nick = username
            user = self._getuser(irc, msg, db, cur)
            if user is None:
                return

        if user['Uploaded'] == 0 and user['Downloaded'] == 0:
            ratio = 0
        elif user['Downloaded'] == 0:
            ratio = u'\u221e'
        else:
            ratio = '%.2f' % (float(user['Uploaded']) / user['Downloaded'])

        irc.reply('Account: %s    Ratio: %s   UL: %s   DL: %s' % (user['Username'], ratio, sizefmt(user['Uploaded']), sizefmt(user['Downloaded'])), prefixNick=False)

    @wrap(['somethingWithoutSpaces', ('something', None, lambda x: x in cat_ids), 'boolean', 'text'])
    def ul(self, irc, msg, args, infohash, cat, scene, name):
        """<infohash> <category name> <1/true if scene else 0/false> <torrent name> - Upload torrent to tracker"""

        if msg.args[0] != chan:
            irc.error('Must ul in %s!' % chan)
            return

        if not is_infohash(infohash):
            irc.error('Invalid infohash')
            return

        infohash = unhexlify(infohash.lower())

        catid = cat_ids[cat]

        with closing(getdb()) as db, closing(db.cursor()) as cur:
            user = self._getuser(irc, msg, db, cur)
            if user is None:
                return
            if user['Enabled'] != '1':
                irc.error('Your tracker account isnt enabled :(')
                return

            cur.execute('SELECT ID FROM torrents WHERE info_hash = %s', (infohash,)) 
            if cur.fetchone():
                irc.error('That torrent already exists!')
                return

            scene = '1' if scene else '0'

            cur.execute('''INSERT INTO torrents (UserId, Name, CategoryID, Scene, info_hash, Size, Time, FreeTorrent)
                        VALUES (%s,%s,%s,%s,%s,%s,%s,%s)''',
                        (user['ID'], name, catid, scene, infohash, 1, sqltime(), 0))
            db.commit()
            self._tracker.update_tracker('add_torrent', {'id': cur.lastrowid, 'info_hash': quote(infohash), 'freetorrent': 0})
            irc.reply('NEW ID %s :: %s :: \x0304%s\x03 :: %s' % (cur.lastrowid, cat, name, 'Scene' if scene=='1' else 'Non-scene'), prefixNick=False)

            if hasattr(self, 'ltses'):
                params = {'ti': None,
                        'name': name,
                        'flags': 516, # upload_mode and update_subscribe
                        'trackers': ['%s/%s/announce' % (tracker_url, bot_passkey)],
                        'info_hash': infohash,
                        'save_path': 'tmp/',
                        'storage_mode': lt.storage_mode_t(2)}
                self.ltses.add_torrent(params)

    @wrap(['owner', 'positiveInt'])
    def rm(self, irc, msg, args, tid):
        """<id> - Remove torrent from tracker"""

        with closing(getdb()) as db, closing(db.cursor()) as cur:
            cur.execute('SELECT UserID, info_hash, Name FROM torrents WHERE ID = %s', (tid,))

            ti = cur.fetchone()
            if ti is None:
                irc.error('Torrent not found')
                return
            else:
                userid, infohash, name = ti
                infohash = str(infohash)

            cur.execute('DELETE FROM torrents WHERE ID = %s', (tid,))
            self._tracker.update_tracker('delete_torrent', {'id': tid, 'info_hash': quote(infohash), 'reason': -1})

            cur.execute('DELETE FROM torrents_files WHERE TorrentID = %s', (tid,))
            db.commit()

        irc.replySuccess()
    
    @wrap(['text'])
    def dl(self, irc, msg, args, name):
        """<id, infohash, or torrent name> - Get the manget link to download it"""

        with closing(getdb()) as db, closing(db.cursor()) as cur:
            user = self._getuser(irc, msg, db, cur)
            if user is None:
                return
            if user['Enabled'] != '1':
                irc.error('Your tracker account isnt enabled :(')
                return

            if is_infohash(name):
                cur.execute('SELECT ID, info_hash, Name, Size FROM torrents WHERE info_hash = %s', (unhexlify(name),))
            elif len(name) < 10 and name.isdigit():
                cur.execute('SELECT ID, info_hash, Name, Size FROM torrents WHERE ID = %s', (name,))
            else:
                cur.execute('SELECT ID, info_hash, Name, Size FROM torrents WHERE Name = %s', (name,))

            torrent = list(cur.fetchone())
            if torrent is None:
                irc.error('Torrent not found')
                return
            if isinstance(torrent[2], unicode):
                torrent[2] = unicodedata.normalize('NFKD', torrent[2]).encode('ascii', 'ignore')
            irc.reply('magnet:?xt=urn:btih:%s&%s&xl=%s&dl=%s&tr=%s/%s/announce' %
                    (hexlify(torrent[1]), urlencode({'dn': torrent[2]}), torrent[3], torrent[3], tracker_url, user['torrent_pass']),
                    private=True)

    @wrap(['text'])
    def info(self, irc, msg, args, name):
        """<id, infohash, or torrent name> - Get more info about it"""
        with closing(getdb()) as db, closing(db.cursor()) as cur:
            user = self._getuser(irc, msg, db, cur)
            if user is None:
                return
            if user['Enabled'] != '1':
                irc.error('Your tracker account isnt enabled :(')
                return

            if is_infohash(name):
                cur.execute('SELECT * FROM torrents WHERE info_hash = %s', (unhexlify(name),))
            elif len(name) < 10 and name.isdigit():
                cur.execute('SELECT * FROM torrents WHERE ID = %s', (name,))
            else:
                cur.execute('SELECT * FROM torrents WHERE Name = %s', (name,))

            torrent = list(cur.fetchone())
            if torrent is None:
                irc.error('Torrent not found')
                return
            if isinstance(torrent[2], unicode):
                torrent[2] = unicodedata.normalize('NFKD', torrent[2]).encode('ascii', 'ignore')

            out = zip(cur.column_names, torrent)

            cur.execute('SELECT Username FROM users_main WHERE ID = %s', (torrent[1],))
            username = cur.fetchone()[0]

            out[1] = ('Uploader', username)

            for line in pprint.pformat(out).split('\n'):
                irc.reply(line.strip(), prefixNick=False)

    @wrap([optional('positiveInt', 1)])
    def list(self, irc, msg, args, page):
        """[page number] - List torrents"""
        with closing(getdb()) as db, closing(db.cursor()) as cur:
            user = self._getuser(irc, msg, db, cur)
            if user is None:
                return
            if user['Enabled'] != '1':
                irc.error('Your tracker account isnt enabled :(')
                return

            limit = '%s, %s' % (20*page-20, 20)

            cur.execute('''SELECT
                                ID, CategoryID, Name, Time, Size, FileCount, Scene, Snatched, Seeders, Leechers
                            FROM torrents
                            ORDER BY ID DESC
                            LIMIT %s''' % limit)
            result = cur.fetchall()

        self._output_torrents(irc, result, page)

    @wrap(['text'])
    def search(self, irc, msg, args, name):
        """<search string> - Search torrents"""
        with closing(getdb()) as db, closing(db.cursor()) as cur:
            user = self._getuser(irc, msg, db, cur)
            if user is None:
                return
            if user['Enabled'] != '1':
                irc.error('Your tracker account isnt enabled :(')
                return

            torrentwhere, data = build_search(name, 'Name', False)
            torrentjoin = ''

            orderby = 'ID'
            orderway = 'DESC'

            query = '''SELECT
                            ID, CategoryID, Name, Time, Size, FileCount, Scene, Snatched, Seeders, Leechers
                        FROM torrents
                        %s
                        %s
                        ORDER BY %s %s
                        LIMIT 20''' % (torrentjoin, torrentwhere, orderby, orderway)

            cur.execute(query, data)
            result = cur.fetchall()
            if not result:
                irc.error('No results')
                return

        self._output_torrents(irc, result, 1)

    def die(self):
        if hasattr(self, 'ltses'):
            del self.ltses
        try:
            schedule.removeEvent('checkmetadata')
            schedule.removeEvent('expiretorrents')
        except KeyError:
            pass



Class = Tracker


# vim:set shiftwidth=4 softtabstop=4 expandtab:
