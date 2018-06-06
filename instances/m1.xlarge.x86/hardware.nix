{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: {
    linux_4_14 = pkgs.linux_4_14.override {
      extraConfig =
        ''
          MLX5_CORE_EN y
        '';
    };
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci" "ehci_pci" "ahci" "megaraid_sas" "sd_mod"
  ];

  boot.kernelPackages = pkgs.linuxPackages_4_14;
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelParams =  [ "console=ttyS1,115200n8" ];
  boot.extraModulePackages = [ ];

  hardware.enableAllFirmware = true;

  nix.maxJobs = 48;
}
