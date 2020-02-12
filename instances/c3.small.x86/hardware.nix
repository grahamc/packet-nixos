{ config, lib, pkgs, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  boot.loader.grub = {
    version = 2;
    efiSupport = true;
    device = "nodev";

    extraConfig = ''
      serial --unit=1 --speed=115200 --word=8 --parity=no --stop=1
      terminal_output serial console
      terminal_input serial console
    '';
  };

  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.kernelModules = [ "kvm_intel" ];
  boot.kernelParams =  [ "console=ttyS1,115200n8" ];
  boot.extraModulePackages = [ ];

  hardware.enableAllFirmware = true;

  nix.maxJobs = 16;
}
