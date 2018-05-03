{ config, lib, pkgs, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      packageOverrides = pkgs:
      { linux_4_9 = pkgs.linux_4_9.override {
          extraConfig =
            ''
              MLX5_CORE_EN y
            '';
        };
      };
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_4_9;

  boot.initrd.availableKernelModules = [
    "ahci" "xhci_pci" "ehci_pci" "mpt3sas" "usbhid" "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelParams =  [ "console=ttyS1,115200n8" ];
  boot.extraModulePackages = [ ];

  hardware.enableAllFirmware = true;

  nix.maxJobs = 32;
}
