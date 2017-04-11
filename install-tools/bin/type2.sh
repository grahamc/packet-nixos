#!/bin/sh

set -eux

. @out@/bin/tools.sh

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

pre_partition

partition | fdisk /dev/sda
partition | fdisk /dev/sdb
partition | fdisk /dev/sdc
partition | fdisk /dev/sdd
partition | fdisk /dev/sde
partition | fdisk /dev/sdf

pre_format

zpool create -o ashift=12 rpool raidz2 /dev/sda1 /dev/sdb1 /dev/sdc1 /dev/sdd1 /dev/sde1 /dev/sdf1

# since all the disks are the same, I'm skipping the SLOG and L2ARC
zfs create -o mountpoint=none rpool/root
zfs create -o compression=lz4 -o mountpoint=legacy rpool/root/nixos

pre_mount
mount -t zfs rpool/root/nixos /mnt
post_mount

generate_standard_config

cat @type2conf@ > /mnt/etc/nixos/hardware-configuration.nix

do_install
do_reboot
