#!/bin/sh

set -eux

. @out@/bin/tools.sh

pre_partition

sgdisk -Z /dev/sdc
partition() {
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF
          o # clear the in memory partition table
          n # new partition
          p # primary partition
          1 # partition number 1
            # default - start at beginning of disk
            # default, extend partition to end of disk
          a # make a partition bootable
          t # Change type
          bf # zfs
          p # print the in-memory partition table
          w # write the partition tableni
EOF

}

sgdisk -Z /dev/sdc

partition | fdisk /dev/sdc

pre_format

zpool create -o ashift=12 rpool /dev/sdc1

zfs create -o compression=lz4 -o mountpoint=legacy rpool/root

pre_mount
mount -t zfs rpool/root /mnt
post_mount

generate_standard_config

cat @typesconf@ > /mnt/etc/nixos/hardware-configuration.nix

do_install
do_reboot
