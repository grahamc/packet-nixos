#!/usr/bin/env nix-shell
#!nix-shell -p expect -i bash

. ./config.sh

ipv4_public=$1

sshopts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
ssh $sshopts root@"$ipv4_public" nixos-rebuild boot
ssh $sshopts root@"$ipv4_public" reboot || true
echo allok
