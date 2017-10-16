let
  pkgs = import <nixpkgs> {};
  mkNixos = import <nixpkgs/nixos>;

  mkPXEInstaller = { name, system, img
    , installTimeConfigFiles ? [ ./base.nix ]  # Used only during install time
    , runTimeConfigFiles # Used only after installation
    , configFiles  # Used during and after install time
    , partition # Partition commands
    , format # formatting commands
    , mount # mount commands
    }: let

    handjam = {
      networking = {
        hostId = "00000000";
      };
    };

    runTimeNixOS = mkNixos {
      inherit system;
      configuration = {
        imports = [handjam] ++ configFiles ++ runTimeConfigFiles;
      };
    };

    installTimeNixos = mkNixos {
      inherit system;
      configuration = {
        imports = [
          <nixpkgs/nixos/modules/installer/netboot/netboot-minimal.nix>
          handjam
        ] ++ installTimeConfigFiles ++ configFiles ++ [
          {
            installer = {
              inherit partition format mount;
              type = "${name}-${system}";
              configFiles = configFiles ++ runTimeConfigFiles;
              runTimeNixOS = "${runTimeNixOS.system}";
            };
          }
        ];
      };
    };

    build = installTimeNixos.config.system.build;
  in pkgs.runCommand name {} ''
    mkdir $out
    ln -s ${build.netbootRamdisk}/initrd $out/initrd
    ln -s ${build.kernel}/${img} $out/${img}
    ln -s ${build.netbootIpxeScript}/netboot.ipxe $out/netboot.ipxe
  '';

  partitionOneLinux = disk: ''
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${disk}
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
  '';

  partitionLinuxWithBoot = disk: ''
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${disk}
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
  '';

  partitionLinuxWithBootSwap = disk: ''
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${disk}
      o # clear the in memory partition table
      n # new partition
      p # primary partition
      1 # partition number 1
        # default - start at beginning of diskp
      +500M # 500MB for /boot
      n # new partition
      p # primary partition
      2 # partition number 2
        # default - start at beginning of disk
      +2G # 2G for swap
      n # New partition
      p # Primary
      3 # #3, primary disk
        # default start
        # default, extend partition to end of disk
      t # change type
      1 # partition 1
      ef # Type EFI
      p # print the in-memory partition table
      w # write the partition table
    EOF
  '';

  partitionLinuxWithSwap = disk: ''
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${disk}
      o # clear the in memory partition table
      n # New partition
      p # Primary
      1 # Partition #1
        # default, extend after the previous
      +2G # 2G partition for swap
      n # New partition
      p # Primary
      2 # #2
        # default start
        # default, extend partition to end of disk
      t # change type
      2 # Partition #2
      ef # Type EFI
      p # print the in-memory partition table
      w # write the partition table
    EOF
  '';


  partitionOneZFS = disk: ''
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${disk}
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
      w # write the partition table
    EOF
  '';

in rec {
  all-x86-64 = pkgs.runCommand "nixos-all-x86-64" {}
    ''
      mkdir $out
      ln -s ${type-0} $out/type-0
      ln -s ${type-1} $out/type-1
      ln -s ${type-2} $out/type-2
      ln -s ${type-3} $out/type-3
      ln -s ${type-s} $out/type-s
    '';

  type-0 = mkPXEInstaller {
    name = "type-0";
    system = "x86_64-linux";
    img = "bzImage";

    configFiles = [
      ./instances/standard.nix
      ./instances/type-0/hardware.nix
    ];

    runTimeConfigFiles = [
      ./instances/type-0/installed.nix
    ];

    partition = partitionLinuxWithSwap "/dev/sda";

    format = ''
      mkswap -L swap /dev/sda1
      mkfs.ext4 -L nixos /dev/sda2
    '';

    mount = ''
      swapon /dev/sda1
      mount /dev/disk/by-label/nixos /mnt
    '';
  };

  type-1 = mkPXEInstaller {
    name = "type-1";
    system = "x86_64-linux";
    img = "bzImage";

    configFiles = [
      ./instances/standard.nix
      ./instances/type-1/hardware.nix
    ];

    runTimeConfigFiles = [
      ./instances/type-1/installed.nix
    ];

    partition = ''
      ${partitionLinuxWithBootSwap "/dev/sda"}
      sfdisk -d /dev/sda | sfdisk /dev/sdb

      udevadm settle

      yes | mdadm --create --verbose /dev/md0 --level=1 /dev/sda2 /dev/sdb2 -n2
      yes | mdadm --create --verbose /dev/md1 --level=1 /dev/sda3 /dev/sdb3 -n2
    '';

    format = ''
      mkswap -L swap /dev/md0
      mkfs.ext4 -L nixos /dev/md1
    '';

    mount = ''
      swapon -L swap
      mount -L nixos /mnt
    '';
  };

  type-2a = mkPXEInstaller {
    name = "type-2a";
    system = "aarch64-linux";
    img = "Image";

    installTimeConfigFiles = [
      ./base.nix
      ./instances/type-2a/installer.nix
    ];

    configFiles = [
      ./instances/standard.nix
      ./instances/type-2a/hardware.nix
    ];

    runTimeConfigFiles = [
      ./instances/type-2a/installed.nix
    ];

    partition = partitionLinuxWithBoot "/dev/sda";

    format = ''
      mkfs.vfat /dev/sda1
      mkfs.ext4 -L nixos /dev/sda2
    '';

    mount = ''
      mount /dev/disk/by-label/nixos /mnt
      mkdir -p /mnt/boot/efi
      mount /dev/sda1 /mnt/boot/efi
    '';
  };

  type-2 = mkPXEInstaller {
    name = "type-2";
    system = "x86_64-linux";
    img = "bzImage";

    configFiles = [
      ./instances/standard.nix
      ./instances/type-2/hardware.nix
    ];

    runTimeConfigFiles = [
      ./instances/type-2/installed.nix
    ];

    partition = ''
      ${partitionOneZFS "/dev/sda"}
      ${partitionOneZFS "/dev/sdb"}
      ${partitionOneZFS "/dev/sdc"}
      ${partitionOneZFS "/dev/sdd"}
      ${partitionOneZFS "/dev/sde"}
      ${partitionOneZFS "/dev/sdf"}
    '';

    format = ''
      zpool create -o ashift=12 rpool raidz2 /dev/sda1 /dev/sdb1 /dev/sdc1 /dev/sdd1 /dev/sde1 /dev/sdf1

      # since all the disks are the same, I'm skipping the SLOG and L2ARC
      zfs create -o mountpoint=none rpool/root
      zfs create -o compression=lz4 -o mountpoint=legacy rpool/root/nixos
    '';

    mount = ''
      mount -t zfs rpool/root/nixos /mnt
    '';
  };

  type-3 = mkPXEInstaller {
    name = "type-3";
    system = "x86_64-linux";
    img = "bzImage";

    configFiles = [
      ./instances/standard.nix
      ./instances/type-3/hardware.nix
    ];

    runTimeConfigFiles = [
      ./instances/type-3/installed.nix
    ];

    partition = ''
      ${partitionOneZFS "/dev/sda"}
      ${partitionOneZFS "/dev/sdb"}
    '';

    format = ''
      zpool create -o ashift=12 rpool raidz /dev/sda1 /dev/sdb1

      # since all the disks are the same, I'm skipping the SLOG and L2ARC
      zfs create -o mountpoint=none rpool/root
      zfs create -o compression=lz4 -o mountpoint=legacy rpool/root/nixos
    '';

    mount = ''
      mount -t zfs rpool/root/nixos /mnt
    '';
  };

  type-s = mkPXEInstaller {
    name = "type-s";
    system ="x86_64-linux";
    img = "bzImage";

    configFiles = [
      ./instances/standard.nix
      ./instances/type-s/hardware.nix
    ];

    runTimeConfigFiles = [
      ./instances/type-s/installed.nix
    ];

    partition = partitionOneZFS "/dev/sdc";

    format = ''
      zpool create -o ashift=12 rpool /dev/sdc1
      zfs create -o compression=lz4 -o mountpoint=legacy rpool/root
    '';

    mount = ''
      mount -t zfs rpool/root /mnt
    '';
  };
}
