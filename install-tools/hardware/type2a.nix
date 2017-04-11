{ lib, ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub = {
        enable = true;
        version = 2;
        efiSupport = true;
        device = "nodev";
        efiInstallAsRemovable = true;
      };
      efi = {
        efiSysMountPoint = "/boot/efi";
        canTouchEfiVariables = lib.mkForce false;
      };
    };

    initrd = {
      availableKernelModules = [ "ahci" "pci_thunder_ecam" ];
    };

    kernelParams = [
      "cma=0M" "biosdevname=0" "net.ifnames=0" "console=ttyAMA0"
    ];
    # kernelPackages = pkgs.linuxPackages_4_9;
  };

  fileSystems = {
    "/" = {
      device = "/dev/sda2";
      fsType = "ext4";
    };
    "/boot/efi" = {
      device = "/dev/sda1";
      fsType = "vfat";
    };
  };

  nix = {
    maxJobs = 96;
  };
  nixpkgs = {
    system = "aarch64-linux";
  };
}
