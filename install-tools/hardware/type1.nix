{ config, lib, pkgs, ... }:
{
  boot = {
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
        devices = [ "/dev/sda" "/dev/sdb" ];
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
  };

  hardware = {
    enableAllFirmware = true;
  };

  nix = {
    maxJobs = 8;
  };
}
