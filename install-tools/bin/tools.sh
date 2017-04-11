#!/bin/sh

set -eux

PATH=@packetconfiggen@/bin:@coreutils@/bin:@utillinux@/bin:@e2fsprogs@/bin:@out@/bin:/run/current-system/sw/bin/:$PATH

pre_partition() {
    udevadm settle
}

pre_format() {
    udevadm settle
}

pre_mount() {
    udevadm settle
}

post_mount() {
    udevadm settle
    notify.py partitioned
}

generate_standard_config() {
    nixos-generate-config --root /mnt

    packet-config-gen > /mnt/etc/nixos/packet.nix
    cat @standardconf@ > /mnt/etc/nixos/standard.nix
}
