#!/bin/sh


NIX_REMOTE=daemon nix-build \
    '<nixpkgs/nixos>' \
    -A config.system.build.netbootRamdisk \
    -A config.system.build.kernel \
    -A config.system.build.netbootIpxeScript \
    -I nixos-config=./pxe.nix\
    -Q -j 4

rsync --progress --ignore-times ./result-3/netboot.ipxe ./result-2/bzImage ./result/initrd \
    gchristensen@gsc.io:sites/gsc.io/public/lol-t2/
