#!/usr/bin/python3

from metadata import Metadata
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("-k", "--disable-root-keys", action="store_true")
parser.add_argument("-p", "--disable-root-pw", action="store_true")
args = parser.parse_args()

if args.disable_root_keys:
    root_keys = False
else:
    root_keys = True

if args.disable_root_pw:
    root_pw = False
else:
    root_pw = True


m = Metadata(root_keys, root_pw)

print("".join(m.outputConfig()))
