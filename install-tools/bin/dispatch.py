#!@python3@/bin/python3

from pprint import pprint
import json
import requests
import os

while True:
    try:
        d = requests.get('https://metadata.packet.net/metadata').json()
        break
    except:
        pass

plan = d['plan']

scripts = {
    "baremetal_0": "@out@/bin/type0.sh",
    "baremetal_1": "@out@/bin/type1.sh",
    "baremetal_2": "@out@/bin/type2.sh",
    "baremetal_2a": "@out@/bin/type2a.sh",
    "baremetal_3": "@out@/bin/type3.sh",
    "baremetal_s": "@out@/bin/type-s.sh",
}

if plan in scripts:
        print(scripts[plan])
        os.execl(scripts[plan], scripts[plan])
else:
    print("Cannot handle {}".format(plan))
