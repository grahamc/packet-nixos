#!/bin/sh

set -eux

. @out@/bin/tools.sh

pre_partition

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sda
      o # clear the in memory partition table
      n # new partition
      p # primary partition
      1 # partition number 1
        # default - start at beginning of disk
        # default, extend partition to end of disk
      a # make a partition bootable
      1 # bootable partition is partition 1 -- /dev/sda1
      p # print the in-memory partition table
      w # write the partition table
      q # and we're done
EOF

pre_format

mkfs.ext4 -L nixos /dev/sda1

pre_mount
mount /dev/disk/by-label/nixos /mnt
post_mount

generate_standard_config

cat @type0conf@ > /mnt/etc/nixos/hardware-configuration.nix

sed -i "s#./hardware-configuration.nix#./hardware-configuration.nix ./standard.nix ./packet.nix#" /mnt/etc/nixos/configuration.nix

do_install
do_reboot
