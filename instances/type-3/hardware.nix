{ config, lib, pkgs, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.availableKernelModules = [
    "xhci_pci" "ehci_pci" "ahci" "usbhid" "sd_mod" "megaraid_sas"
    "nvme"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelParams =  [ "console=ttyS1,115200n8" ];
  boot.extraModulePackages = [ ];
  boot.loader.grub.zfsSupport = true;

  hardware.enableAllFirmware = true;

  nix.maxJobs = 40;
}
