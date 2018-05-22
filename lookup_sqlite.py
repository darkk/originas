#!/usr/bin/env python3

import socket
import sqlite3
import struct
import sys

ORIGINAS_FILE = 'originas.sqlite'

def main():
    db = sqlite3.connect(ORIGINAS_FILE)
    for ip_text in sys.argv[1:]:
        ip = socket.inet_aton(ip_text) # 4-byte raw
        ip = struct.unpack('>I', ip)[0] # integer
        c = db.cursor()
        # XXX: sqlite indexes are not well-optimised for that sort of range queries
        # BETWEEN is `<=` for both ends of the range
        c.execute('SELECT netaddr, netmask, asn FROM originas WHERE ? BETWEEN ip_hi AND ip_lo', [ip])
        c = list(c)
        most_specific = max(_[1] for _ in c)
        c = [_ for _ in c if _[1] == most_specific]
        for row in c:
            print('{}\t{}/{}\tAS{}'.format(ip_text, row[0], row[1], row[2]))

if __name__ == '__main__':
    main()
