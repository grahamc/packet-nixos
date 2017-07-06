{ config, lib, pkgs, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

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
  };

  hardware = {
    enableAllFirmware = true;
  };

  nix = {
    maxJobs = 8;
  };
}
