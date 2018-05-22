#!/usr/bin/env python3

import ipaddress
import re
import socket
import struct
import sys
import os

SQLITE, PSQL = object(), object()
MODE = {
    'SQLITE': SQLITE,
    'PSQL': PSQL,
}[os.environ['ORIGINAS_MODE']]

def main():
    reasset = re.compile(r'^[0-9\.*]+\s+IN TXT\s+"({[0-9,]+})" "([0-9\.]+)" "(\d+)"$')
    reas = re.compile(r'^[0-9\.*]+\s+IN TXT\s+"(\d+)" "([0-9\.]+)" "(\d+)"$')
    last = None
    for line in sys.stdin:
        # AS-SET are quite diverse, here are some examples 
        # - "{17916}" "20.133.40.0" "21" -- that's single AS within set
        # - "{7474,17916}" "20.134.0.0" "20" -- that's several ASes within set
        for regex in (reas, reasset):
            m = regex.match(line)
            if m is not None:
                row = m.groups()
                break
        else:
            raise RuntimeError('Unparsable line', line)
        if last != row: # skip consequent duplicates
            asset, ipnet, bits = last = row
            if asset[0] == '{' and asset[-1] == '}':
                asset = map(int, asset[1:-1].split(',')) # XXX: that's, probably, simplification of AS-SET concept
            else:
                asset = [int(asset)]
            for asn in asset:
                if asn < 64512 or 65535 < asn < 4200000000: # drop private ASNs from RFC6996
                    if MODE is PSQL:
                        sys.stdout.write('{}/{}\t{}\n'.format(ipnet, bits, asn))
                    elif MODE is SQLITE:
                        net = ipaddress.ip_network('{}/{}'.format(ipnet, bits))
                        pair = (net.network_address, net.broadcast_address)
                        pair = map(str, pair)
                        pair = map(socket.inet_aton, pair)
                        pair = map(lambda x: struct.unpack('>I', x)[0], pair)
                        hi, lo = pair
                        sys.stdout.write('{}\t{}\t{}\t{:d}\t{:d}\n'.format(ipnet, bits, asn, hi, lo))
                    else:
                        assert MODE in (SQLITE, PSQL)
                else:
                    pass # print('Private ASN:', row, file=sys.stderr)

if __name__ == '__main__':
    main()
