#!/bin/sh

set -eux

PATH=@packetconfiggen@/bin:@coreutils@/bin:@utillinux@/bin:@e2fsprogs@/bin:@mdadm@/bin:@zfs@/bin:@out@/bin:q/run/current-system/sw/bin/:$PATH

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

udevadm settle
partition | fdisk /dev/sda
partition | fdisk /dev/sdb
udevadm settle

zpool create -o ashift=12 rpool raidz /dev/sda1 /dev/sdb1

# since all the disks are the same, I'm skipping the SLOG and L2ARC
zfs create -o mountpoint=none rpool/root
zfs create -o compression=lz4 -o mountpoint=legacy rpool/root/nixos
udevadm settle
mount -t zfs rpool/root/nixos /mnt

notify.py partitioned

nixos-generate-config --root /mnt

hostId=$(printf "00000000%x" $(cksum /etc/machine-id | cut -d' ' -f1) | tail -c8)
echo '{ networking.hostId = "'$hostId'"; }' > /mnt/etc/nixos/host-id.nix
packet-config-gen > /mnt/etc/nixos/packet.nix
cat @standardconf@ > /mnt/etc/nixos/standard.nix
cat @type1conf@ > /mnt/etc/nixos/hardware-configuration.nix

sed -i "s#./hardware-configuration.nix#./hardware-configuration.nix ./standard.nix ./host-id.nix ./packet.nix#" /mnt/etc/nixos/configuration.nix

nixos-install < /dev/null

notify.py installed

reboot
