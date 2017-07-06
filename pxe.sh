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

NIX_REMOTE=daemon nix-build ./default.nix -A "$2" \
          --keep-going --keep-failed --cores 4

rsync -vl --progress --ignore-times ./result/* \
      "$1"
