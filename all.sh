#!/bin/sh

for type in type-0 type-1 type-2 type-3 type-s; do
    mkdir -p "./nixos-ipxe-$type"
    ./pxe.sh "./nixos-ipxe-$type/" "$type"
done
