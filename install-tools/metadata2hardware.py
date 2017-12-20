#!/usr/bin/python3

import requests
from glob import glob
import re

d = requests.get('https://metadata.packet.net/metadata').json()


def mkRootPassword(path):
    cfg = """
      users.users.root.initialHashedPassword = "{}";
    """

    with open(path) as cmdline:
        line = cmdline.read()
        x = re.search(r'pwhash=([^\s]+)', line)
        if x:
            pwhash = x.group(1)
            return cfg.format(pwhash)
    return ""


def mkBonds(blob):
    cfg = """
      networking.bonds.bond0 = {{
        driverOptions.mode = "{mode}";
        interfaces = [
          {interfaces}
        ];
      }};
    """
    interfacePart = '"{}"'

    modes = {4: "802.3ad", 5: "balance-tlb"}
    mode = modes[blob['network']['bonding']['mode']]
    macToName = {open(f).read().strip(): f.split('/')[4] for f in glob('/sys/class/net/*/address')}

    interfaces = [
        interfacePart.format(macToName[interface['mac']])
        for interface in blob['network']['interfaces']
    ]

    return cfg.format(mode=mode, interfaces=" ".join(interfaces))


def mkHostname(blob):
    cfg = """
      networking.hostName = "{}";
    """

    return cfg.format(blob['hostname'])


def mkInterfaces(blob):
    cfg = """
      networking.interfaces.bond0 = {{
        useDHCP = true;

        ip4 = [
          {ip4s}
        ];

        ip6 = [
          {ip6s}
        ];
      }};
    """

    ipPart = """
          {{
            address = "{address}";
            prefixLength = {prefix};
          }}
    """

    ip4s = []
    ip6s = []

    for address in blob['network']['addresses']:
        if address['enabled']:
            part = ipPart.format(address=address['address'], prefix=address['cidr'])
            if address['address_family'] == 4:
                ip4s.append(part)
            elif address['address_family'] == 6:
                ip6s.append(part)

    return cfg.format(ip4s="\n".join(ip4s), ip6s="\n".join(ip6s))


def mkRootKeys(blob):
    cfg = """
      users.users.root.openssh.authorizedKeys.keys = [{keys}
      ];
    """
    keyPart = """
        "{}"
    """

    keyParts = [keyPart.format(key) for key in blob['ssh_keys']]

    return cfg.format(keys="\n".join(keyParts))


configParts = [
    mkHostname(d),
    mkBonds(d),
    mkInterfaces(d),
    mkRootKeys(d),
    mkRootPassword('/proc/cmdline')
]
print("{", "".join(configParts), "}")
