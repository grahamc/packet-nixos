{ pkgs, ... }:
{
  boot = {
   loader = {
      grub = {
        version = 2;
        efiSupport = true;
        device = "nodev";
        efiInstallAsRemovable = true;
      };
    };

    initrd = {
      availableKernelModules = [ "ahci" "pci_thunder_ecam" ];
    };

    kernelParams = [
      "cma=0M" "biosdevname=0" "net.ifnames=0" "console=ttyAMA0"
    ];
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
