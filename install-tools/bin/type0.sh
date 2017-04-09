#!/bin/sh

set -eux

PATH=@packetconfiggen@/bin:@coreutils@/bin:@utillinux@/bin:@e2fsprogs@/bin:/run/current-system/sw/bin/:$PATH

udevadm settle
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

udevadm settle
mkfs.ext4 -L nixos /dev/sda1
udevadm settle
mount /dev/disk/by-label/nixos /mnt
udevadm settle
nixos-generate-config --root /mnt

packet-config-gen > /mnt/etc/nixos/packet.nix
cat @standardconf@ > /mnt/etc/nixos/standard.nix
cat @type0conf@ > /mnt/etc/nixos/hardware-configuration.nix

sed -i "s#./hardware-configuration.nix#./hardware-configuration.nix ./standard.nix ./packet.nix#" /mnt/etc/nixos/configuration.nix

nixos-install < /dev/null

reboot
