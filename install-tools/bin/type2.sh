#!/bin/sh

set -eux

PATH=@packetconfiggen@/bin:@coreutils@/bin:@utillinux@/bin:@e2fsprogs@/bin:@mdadm@/bin:@zfs@/bin:/run/current-system/sw/bin/:$PATH

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

udevadm settle
partition | fdisk /dev/sda
partition | fdisk /dev/sdb
partition | fdisk /dev/sdc
partition | fdisk /dev/sdd
partition | fdisk /dev/sde
partition | fdisk /dev/sdf
udevadm settle

zpool create -o ashift=12 rpool raidz2 /dev/sda1 /dev/sdb1 /dev/sdc1 /dev/sdd1 /dev/sde1 /dev/sdf1

# since all the disks are the same, I'm skipping the SLOG and L2ARC
zfs create -o mountpoint=none rpool/root
zfs create -o compression=lz4 -o mountpoint=legacy rpool/root/nixos
udevadm settle
mount -t zfs rpool/root/nixos /mnt

nixos-generate-config --root /mnt

hostId=$(printf "00000000%x" $(cksum /etc/machine-id | cut -d' ' -f1) | tail -c8)
echo '{ networking.hostId = "'$hostId'"; }' > /mnt/etc/nixos/host-id.nix
packet-config-gen > /mnt/etc/nixos/packet.nix
cat @standardconf@ > /mnt/etc/nixos/standard.nix
cat @type2conf@ > /mnt/etc/nixos/hardware-configuration.nix

sed -i "s#./hardware-configuration.nix#./hardware-configuration.nix ./standard.nix ./host-id.nix ./packet.nix#" /mnt/etc/nixos/configuration.nix

nixos-install < /dev/null

reboot
