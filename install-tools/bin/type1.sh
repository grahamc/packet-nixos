#!/bin/sh

set -eux

PATH=@packetconfiggen@/bin:@coreutils@/bin:@utillinux@/bin:@e2fsprogs@/bin:@mdadm@/bin:$PATH

partition() {
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF
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

}

if [ ! -b /dev/md0 ]; then
    partition | fdisk /dev/sda
    partition | fdisk /dev/sdb

    mdadm --create --verbose /dev/md0 --level=mirror \
          --raid-devices=2 /dev/sda1 /dev/sdb1 --metadata=0.90
fi

mkfs.ext4 -L nixos /dev/md0 < /dev/null
sleep 5
mount /dev/disk/by-label/nixos /mnt

nixos-generate-config --root /mnt

packet-config-gen > /mnt/etc/nixos/packet.nix
cat @standardconf@ > /mnt/etc/nixos/standard.nix
cat @type1conf@ > /mnt/etc/nixos/hardware-configuration.nix

sed -i "s#./hardware-configuration.nix#./hardware-configuration.nix ./standard.nix ./packet.nix#" /mnt/etc/nixos/configuration.nix

nixos-install < /dev/null

reboot
