#!@python3@/bin/python3

from pprint import pprint
import json
import requests
import os
import sys


def cb_partitioned(url, instance_id):
    requests.put(url, json={"type": "provisioning.105", "body": "Server partitions created"})
    print("Announced partitions")


def cb_installed(url, instance_id):
    requests.put(
        url, json={
            "type": "provisioning.109",
            "body": "Installation finished, rebooting server"
        })
    print("Announced installed")


def cb_booted(url, instance_id):
    print("curl -H 'Content-Type: application/json' -d'{}' {}".format(
        '{{"instance_id": "{}"}}'.format(instance_id), url))


cbs = {
    "partitioned": cb_partitioned,
    "installed": cb_installed,
    "booted": cb_booted,
}

if len(sys.argv) != 2 or sys.argv[1] not in cbs:
    print("notify.py {}".format("|".join(cbs.keys())))
    sys.exit(1)
else:
    callback = cbs[sys.argv[1]]

while True:
    try:
        d = requests.get('https://metadata.packet.net/metadata').json()
        break
    except:
        pass

url = d['phone_home_url']
instance_id = d['id']
callback(url, instance_id)
