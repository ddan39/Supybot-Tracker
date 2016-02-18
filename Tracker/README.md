IRC Channel BitTorrent Tracker front-end. Communicates with ocelot tracker and gazelle-based tracker db.(modified for general content instead of groups). A few things are straight ported from gazelle/ocelot php.

Also can run libtorrent client session which grabs metadata(file list, size, etc.) from swarm and inputs into db/channel.

Must add ocelot passwords into ocelot.py

Uses Anope IRC Services for accounts. Requires anope xmlrpc api on http://127.0.0.1:8080/xmlrpc
