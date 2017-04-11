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
      +500M # 500MB for /boot
      n # New partition
      p # Primary
      2 # #2
        # default start
        # default, extend partition to end of disk
      t # change type
      1 # partition 1
      ef # Type EFI
      p # print the in-memory partition table
      w # write the partition table
EOF

pre_format

mkfs.vfat /dev/sda1
mkfs.ext4 -L nixos /dev/sda2

pre_mount

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

post_mount

generate_standard_config
cat @type2aconf@ > /mnt/etc/nixos/hardware-configuration.nix

sed -i "s#./hardware-configuration.nix#./hardware-configuration.nix ./standard.nix ./packet.nix#" /mnt/etc/nixos/configuration.nix

do_install
do_reboot
