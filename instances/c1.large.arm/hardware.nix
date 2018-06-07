{ pkgs, ... }:
{
  boot = {
   loader = {
      grub = {
        version = 2;
        efiSupport = true;
        device = "nodev";
        efiInstallAsRemovable = true;
        font = null;
        splashImage = null;
      };
    };

    initrd = {
      availableKernelModules = [ "ahci" "pci_thunder_ecam" ];
    };

    kernelParams = [
      "cma=0M" "biosdevname=0" "net.ifnames=0" "console=ttyAMA0"
    ];

    kernelPackages = pkgs.linuxPackages_4_14;
  };

  nix = {
    maxJobs = 96;
  };
  nixpkgs = {
    system = "aarch64-linux";
    config = {
      allowUnfree = true;
    };
  };
}
