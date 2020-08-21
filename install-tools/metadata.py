#!/usr/bin/python3

import requests
import subprocess
from glob import glob
import re

class Metadata:
    metadataJson = requests.get('https://metadata.packet.net/metadata').json()
    includeRootKeys = True
    includeRootPW = True

    def __init__(self, include_root_keys=True, include_root_pw=True):
        self.includeRootKeys = include_root_keys
        self.includeRootPW = include_root_pw


    def mkRootPassword(self, path):
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


    def mkBonds(self):
        cfg = """
          networking.bonds.bond0 = {{
            driverOptions = {{
    {bonding_options}
            }};

            interfaces = [
              {interfaces}
            ];
          }};
        """
        interfacePart = '"{}"'

        mode_to_options = {4: """
              mode = "802.3ad";
              xmit_hash_policy = "layer3+4";
              lacp_rate = "fast";
              downdelay = "200";
              miimon = "100";
              updelay = "200";
    """,
                           5: """
              mode = "balance-tlb";
              xmit_hash_policy = "layer3+4";
              downdelay = "200";
              updelay = "200";
              miimon = "100";
    """
                           }
        mode_options = mode_to_options[self.metadataJson['network']['bonding']['mode']]
        macToName = self.collectMacToName()

        interfaces = [
            interfacePart.format(macToName[interface['mac']])
            for interface in self.metadataJson['network']['interfaces']
            if interface['bond'] == 'bond0'
        ]

        return cfg.format(bonding_options=mode_options.strip("\n"),
                          interfaces=" ".join(interfaces))


    def collectMacToName(self):
        interfaces = [filename.split('/')[4]
                      for filename in glob('/sys/class/net/*/address')
                      if filename.split('/')[4] != 'bond0']
        mac_to_name = {self.nic_permaddr(interface): interface
                       for interface in interfaces}
        return mac_to_name


    def nic_permaddr(self, interface):
        output = subprocess.check_output(['ethtool', '--show-permaddr', interface])
        return output.decode("utf-8").strip().split()[-1]


    def mkNetworking(self, path):
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
            'hostname': self.metadataJson['hostname'],
        }

        for address in self.metadataJson['network']['addresses']:
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

        vals['nameservers'] = '\n'.join(['        "%s"' % ns
                                         for ns in nameservers])
        for exp in ('hostname', 'gateway', 'gateway6', 'nameservers'):
            assert exp in vals, 'missing configuration data: %s' % exp

        return cfg.format(**vals)


    def mkInterfaces(self):
        cfg = """
          networking.interfaces.bond0 = {{
            useDHCP = false;

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

        for address in self.metadataJson['network']['addresses']:
            if address['enabled']:
                if not address['public']:
                    privateipv4gateway = address['gateway']
                part = ipPart.format(address=address['address'],
                                     prefix=address['cidr'])
                if address['address_family'] == 4:
                    ip4s.append(part)
                elif address['address_family'] == 6:
                    ip6s.append(part)

        return cfg.format(ip4s="\n".join(ip4s), ip6s="\n".join(ip6s),
                          privateipv4gateway=privateipv4gateway)


    def mkRootKeys(self):
        cfg = """
          users.users.root.openssh.authorizedKeys.keys = [{keys}
          ];
        """
        keyPart = """
            "{}"
        """

        keyParts = [keyPart.format(key) for key in self.metadataJson['ssh_keys']]

        return cfg.format(keys="\n".join(keyParts))

    def outputConfig(self):
        configParts = [
            self.mkNetworking("/etc/resolv.conf"),
            self.mkBonds(),
            self.mkInterfaces()
        ]
        if self.includeRootKeys:
            configParts.append(self.mkRootKeys())
        if self.includeRootPW:
            configParts.append(self.mkRootPassword('/proc/cmdline'))
        return "{", "".join(configParts), "}"
