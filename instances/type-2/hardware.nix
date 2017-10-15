{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: {
    linux_4_9 = pkgs.linux_4_9.override {
      extraConfig =
        ''
          MLX5_CORE_EN y
        '';
    };
  };

  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.availableKernelModules = [
    "xhci_pci" "ehci_pci" "ahci" "megaraid_sas" "sd_mod"
  ];

  boot.kernelPackages = pkgs.linuxPackages_4_9;
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelParams =  [ "console=ttyS1,115200n8" ];
  boot.extraModulePackages = [ ];
  boot.loader.grub.zfsSupport = true;

  hardware.enableAllFirmware = true;

  nix.maxJobs = 48;
}
