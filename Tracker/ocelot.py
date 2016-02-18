import time
import socket
import traceback
from contextlib import closing

oc_pw = '' # Ocelot site password
oc_rp = '' # Ocelot reports password

class Ocelot:
    """
    this is has methods to communicate with ocelot tracker backend
    """
    STATS_MAIN = 0
    STATS_USER = 1

    def __init__(self):
        self.requests = []

    def update_tracker(self, action, updates):
        """
        update tracker. sends GET request and returns results

        :param action: action to be done on tracker.
        :type action: string

        :param updates: key->value strings to be sent to tracker
        :type updates: dictionary 

        :returns: text data from tracker or None on failure
        :rtpe: string or None
        """
        get = '%s/update?action=%s' % (oc_pw, action)
        for k,v in updates.items():
            get += '&%s=%s' % (k,v)
            
        return self.send_request(get, 3)

    def global_peer_count(self):
        """
        get global peer stats from tracker.

        :returns: (leechers, seeders)
        :rtype: tuple or None on failure
        """
        stats = self.get_stats(self.STATS_MAIN)
        if stats is None:
            return None
        if 'leechers tracked' in stats and 'seeders tracked' in stats:
            return (stats['leechers tracked'], stats['seeders tracked'])
        else:
            return None

    def user_peer_count(self, passkey):
        """
        get peer stats for a user from tracker

        :param passkey: the user's unique passkey
        :type passkey: string, exactly 32 length
        """
        stats = self.get_stats(self.STATS_USER, {'key': passkey})
        if stats is None:
            return None
        if 'leeching' in stats and 'seeding' in stats:
            return (stats['leeching'], stats['seeding'])
        else:
            return (0, 0)

    def info():
        """
        just returns whatever stats the tracker does

        :returns: stats
        :rtype: dictionary, or None on failure
        """
        return self.get_stats(self.STATS_MAIN)

    def get_stats(self, statstype, params=False):
        """
        Send stats request to tracker and process results

        :param statstype: Type of stats to get
        :type statstype: integer

        :param params: Paramters required by stats type
        :type params: dictionary {'key-string': 'value-string'}

        :returns: the stats or None on failure
        :rtpe: dictionary
        """
        
        # put together the get string
        getparts = [oc_rp, '/report?']
        
        if statstype == self.STATS_MAIN:
            getparts.append('get=stats')
        elif statstype == self.STATS_USER and 'key' in params:
            getparts.append('get=user&key=')
            getparts.append(params['key'])
        else:
            return None

        # send get request and make sure it works
        resp = self.send_request(''.join(getparts))
        if resp is None:
            return None
        
        # return results
        return dict(a.split(' ', 1)[::-1] for a in resp.split('\n'))

    def send_request(self, get, maxattempts=1):
        """
        send HTTP GET request to tracker

        :param get: get request to send
        :type get: string

        :param maxattempts: number of retries contacting tracker until success, 
                            meaning socket connects, sends AND we receive a "success" reply
        :type maxattempts: integer

        :returns: text data from tracker or None on failure
        :rtype: string or None
        """
        
        header = "GET /%s HTTP/1.1\r\nConnection: Close\r\n\r\n" % get
        attempts = 0
        sleep = 0
        starttime = time.time()
        resp = ''
        status = 'failed'
        while attempts < maxattempts:
            attempts += 1

            if sleep:
                time.sleep(sleep)

            # send request
            with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as s:
                try:
                    s.connect(('127.0.0.1', 13777))
                    s.sendall(header)
                except:
                    print 'send_request socket failed'
                    traceback.print_exc()
                    sleep = 3
                    continue

                # get response
                while True:
                    buf = s.recv(1024)
                    if buf:
                        resp += buf
                    else:
                        break

            # check response
            try:
                start = resp.index("\r\n\r\n") + 4
                end = resp.rindex("\n", start)
                data = resp[start:end]
                if resp[end+1:] == 'success':
                    status = 'ok'
                else:
                    continue
            except ValueError:
                pass

            break

        self.requests.append({
            'path': get[get.find('/'):],
            'response': data if status=='ok' else resp,
            'status': status,
            'time': 1000 * (time.time() - starttime)
            })

        if status == 'ok':
            return data
        else:
            return None
