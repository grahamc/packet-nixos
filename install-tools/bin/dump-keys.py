#!@python3@/bin/python3

from pprint import pprint
import json
import requests
from glob import glob
import sys

while True:
    try:
        d = requests.get('https://metadata.packet.net/metadata').json()
        break
    except Exception as e:
        pprint(e, stream=sys.stderr)
        pass

print("\n".join(d['ssh_keys']))
