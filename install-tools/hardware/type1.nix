{ config, lib, pkgs, ... }:
{
  boot = {
    supportedFilesystems = [ "zfs" ];
    initrd = {
      availableKernelModules = [
        "xhci_pci" "ehci_pci" "ahci" "usbhid" "sd_mod"
      ];
    };
    kernelModules = [ "kvm-intel" ];
    kernelParams =  [ "console=ttyS1,115200n8" ];
    extraModulePackages = [ ];
    loader = {
      grub = {
        zfsSupport = true;
        devices = [ "/dev/sda" "/dev/sdb" ];
      };
    };
  };

  services.zfs.autoScrub.enable = true;

  fileSystems = {
    "/" = {
      device = "rpool/root/nixos";
      fsType = "zfs";
    };
  };

  hardware = {
    enableAllFirmware = true;
  };

  nix = {
    maxJobs = 8;
  };
}
