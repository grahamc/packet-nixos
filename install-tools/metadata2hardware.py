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


def mkNetworking(blob, path):
    cfg = """
      networking.hostName = "{hostname}";
      networking.dhcpcd.enable = false;
      networking.defaultGateway = {{
        address =  "{gateway}";
        interface = "bond0";
      }};
      networking.defaultGateway6 = {{
        address = "{gateway6}";
        interface = "bond0";
      }};
      networking.nameservers = [\n{nameservers}
      ];
    """

    vals = {
        'hostname': blob['hostname'],
    }

    for address in blob['network']['addresses']:
        if not (address['enabled'] and address['public']):
            continue

        if address['address_family'] == 4:
            vals['gateway'] = address['gateway']
        elif address['address_family'] == 6:
            vals['gateway6'] = address['gateway']

    nameservers = []
    with open(path) as resolvconf:
        for line in resolvconf:
            x = re.search(r'^nameserver\s+([^\s]+)', line)
            if x:
                nameservers.append(x.group(1))

    if not nameservers:
        nameservers = [
            '147.75.207.207',
            '147.75.207.208',
        ]

    vals['nameservers'] = '\n'.join(['        "%s"' % ns for ns in nameservers])
    for exp in ('hostname', 'gateway', 'gateway6', 'nameservers'):
        assert exp in vals, 'missing configuration data: %s' % exp

    return cfg.format(**vals)


def mkInterfaces(blob):
    cfg = """
      networking.interfaces.bond0 = {{
        useDHCP = true;

        ipv4 = {{
          routes = [
            {{
              address = "10.0.0.0";
              prefixLength = 8;
              via = "{privateipv4gateway}";
            }}
          ];
          addresses = [\n{ip4s}
          ];
        }};

        ipv6 = {{
          addresses = [\n{ip6s}
          ];
        }};
      }};
    """

    ipPart = """            {{
              address = "{address}";
              prefixLength = {prefix};
            }}"""

    privateipv4gateway = ""
    ip4s = []
    ip6s = []

    for address in blob['network']['addresses']:
        if address['enabled']:
            if not address['public']:
                privateipv4gateway = address['gateway']
            part = ipPart.format(address=address['address'], prefix=address['cidr'])
            if address['address_family'] == 4:
                ip4s.append(part)
            elif address['address_family'] == 6:
                ip6s.append(part)

    return cfg.format(ip4s="\n".join(ip4s), ip6s="\n".join(ip6s), privateipv4gateway=privateipv4gateway)


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
    mkNetworking(d, "/etc/resolv.conf"),
    mkBonds(d),
    mkInterfaces(d),
    mkRootKeys(d),
    mkRootPassword('/proc/cmdline')
]
print("{", "".join(configParts), "}")
