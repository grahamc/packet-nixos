#!/bin/sh



if [ "x$1" = "x" ]; then
    echo "$0 <rsync-target> <arch>"
    echo "ex: gsc.io:sites/gsc.io/public/nixos-packet-ipxe x86-64|aarch64"
    exit 1
fi
if [ "x$2" = "x" ]; then
    echo "$0 <rsync-target> <arch>"
    echo "ex: gsc.io:sites/gsc.io/public/nixos-packet-ipxe x86-64|aarch64"
    exit 1
fi

set -x

if [ "$2" == "aarch64" ]; then
    NIX_REMOTE=daemon nix-build \
              '<nixpkgs/nixos>' \
              -A config.system.build.netbootRamdisk \
              -A config.system.build.kernel \
              -A config.system.build.netbootIpxeScript \
              -I nixos-config=./aarch64.nix\
              --keep-going --keep-failed

    rsync --progress --ignore-times ./result-3/netboot.ipxe ./result-2/Image ./result/initrd \
          "$1"
else
    NIX_REMOTE=daemon nix-build \
              '<nixpkgs/nixos>' \
              -A config.system.build.netbootRamdisk \
              -A config.system.build.kernel \
              -A config.system.build.netbootIpxeScript \
              -I nixos-config=./x86-64.nix\
              --keep-going --keep-failed

    rsync --progress --ignore-times ./result-3/netboot.ipxe ./result-2/bzImage ./result/initrd \
          "$1"
fi
