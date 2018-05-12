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
  t1-small-x86 = mkPXEInstaller {
    name = "t1.small.x86";
    system = "x86_64-linux";
    img = "bzImage";

    configFiles = [
      ./instances/standard.nix
      ./instances/t1.small.x86/hardware.nix
    ];

    runTimeConfigFiles = [
      ./instances/t1.small.x86/installed.nix
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

  c1-small-x86 = mkPXEInstaller {
    name = "c1.small.x86";
    system = "x86_64-linux";
    img = "bzImage";

    configFiles = [
      ./instances/standard.nix
      ./instances/c1.small.x86/hardware.nix
    ];

    runTimeConfigFiles = [
      ./instances/c1.small.x86/installed.nix
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

  c1-large-arm = mkPXEInstaller {
    name = "c1.large.arm";
    system = "aarch64-linux";
    img = "Image";

    installTimeConfigFiles = [
      ./base.nix
      ./instances/c1.large.arm/installer.nix
    ];

    configFiles = [
      ./instances/standard.nix
      ./instances/c1.large.arm/hardware.nix
    ];

    runTimeConfigFiles = [
      ./instances/c1.large.arm/installed.nix
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

  m1-xlarge-x86 = mkPXEInstaller {
    name = "m1.xlarge.x86";
    system = "x86_64-linux";
    img = "bzImage";

    configFiles = [
      ./instances/standard.nix
      ./instances/m1.xlarge.x86/hardware.nix
    ];

    runTimeConfigFiles = [
      ./instances/m1.xlarge.x86/installed.nix
    ];

    partition = ''
      ${partitionLinuxWithBootSwap "/dev/sda"}
    '';

    format = ''
      mkswap -L swap /dev/sda2
      mkfs.ext4 -L nixos /dev/sda3
    '';

    mount = ''
      swapon -L swap
      mount -L nixos /mnt
    '';
  };

  c1-xlarge-x86 = mkPXEInstaller {
    name = "c1.xlarge.x86";
    system = "x86_64-linux";
    img = "bzImage";

    configFiles = [
      ./instances/standard.nix
      ./instances/c1.xlarge.x86/hardware.nix
    ];

    runTimeConfigFiles = [
      ./instances/c1.xlarge.x86/installed.nix
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

  s1-large-x86 = mkPXEInstaller {
    name = "s1.large.x86";
    system ="x86_64-linux";
    img = "bzImage";

    configFiles = [
      ./instances/standard.nix
      ./instances/s1.large.x86/hardware.nix
    ];

    runTimeConfigFiles = [
      ./instances/s1.large.x86/installed.nix
    ];

    partition = ''
      ${partitionLinuxWithBootSwap "/dev/sdo"}
    '';

    format = ''
      mkswap -L swap /dev/sdo2
      mkfs.ext4 -L nixos /dev/sdo3
    '';

    mount = ''
      swapon -L swap
      mount -L nixos /mnt
    '';
  };

  c2-medium-x86 = mkPXEInstaller {
    name = "c2.medium.x86";
    system = "x86_64-linux";
    img = "bzImage";

    configFiles = [
      ./instances/standard.nix
      # ./instances/c2.medium.x86/hardware.nix
    ];

    runTimeConfigFiles = [
      # ./instances/c2.medium.x86/installed.nix
    ];

    partition = ''
      exit 1
    '';

    format = ''
      exit 1
    '';

    mount = ''
      exit 1
    '';
  };

  x1-small-x86 = mkPXEInstaller {
    name = "x1.small.x86";
    system = "x86_64-linux";
    img = "bzImage";

    configFiles = [
      ./instances/standard.nix
      # ./instances/x1.small.x86/hardware.nix
    ];

    runTimeConfigFiles = [
      # ./instances/x1.small.x86/installed.nix
    ];

    partition = ''
      exit 1
    '';

    format = ''
      exit 1
    '';

    mount = ''
      exit 1
    '';
  };

  m2-xlarge-x86 = mkPXEInstaller {
    name = "m2.xlarge.x86";
    system = "x86_64-linux";
    img = "bzImage";

    configFiles = [
      ./instances/standard.nix
      # ./instances/m2.xlarge.x86/hardware.nix
    ];

    runTimeConfigFiles = [
      # ./instances/m2.xlarge.x86/installed.nix
    ];

    partition = ''
      exit 1
    '';

    format = ''
      exit 1
    '';

    mount = ''
      exit 1
    '';
  };
}
