#!@python3@/bin/python3

from pprint import pprint
import json
import requests
from glob import glob

while True:
    try:
        d = requests.get('https://metadata.packet.net/metadata').json()
        break
    except:
        pass

print("\n".join(d['ssh_keys']))
