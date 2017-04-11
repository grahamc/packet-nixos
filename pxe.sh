#!/bin/sh

if [ "x$1" = "x" ]; then
    echo "$0 <rsync-target>"
    echo "ex: gsc.io:sites/gsc.io/public/nixos-packet-ipxe"
    exit 1
fi

set -eu

NIX_REMOTE=daemon nix-build \
    '<nixpkgs/nixos>' \
    -A config.system.build.netbootRamdisk \
    -A config.system.build.kernel \
    -A config.system.build.netbootIpxeScript \
    -I nixos-config=./aarch64.nix\
    --keep-going --keep-failed

rsync --progress --ignore-times ./result-3/netboot.ipxe ./result-2/Image ./result/initrd \
      "$1"
