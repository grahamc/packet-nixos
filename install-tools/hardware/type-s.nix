{ config, lib, pkgs, ... }:
{
  nixpkgs.config.packageOverrides = pkgs:
  { linux_4_9 = pkgs.linux_4_9.override {
      extraConfig =
        ''
          MLX5_CORE_EN y
        '';
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_4_9;

    supportedFilesystems = [ "zfs" ];
    initrd = {
      availableKernelModules = [
        "ahci" "xhci_pci" "ehci_pci" "mpt3sas" "usbhid" "sd_mod"
      ];
    };
    kernelModules = [ "kvm-intel" ];
    kernelParams =  [ "console=ttyS1,115200n8" ];
    extraModulePackages = [ ];
    loader = {
      grub = {
        zfsSupport = true;
        devices = [
          "/dev/sdc"
        ];
      };
    };
  };

  services.zfs.autoScrub.enable = true;

  fileSystems = {
    "/" = {
      device = "rpool/root";
      fsType = "zfs";
    };
  };

  hardware = {
    enableAllFirmware = true;
  };

  nix = {
    maxJobs = 32;
  };
}
