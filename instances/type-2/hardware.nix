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
        "xhci_pci" "ehci_pci" "ahci" "megaraid_sas" "sd_mod"
      ];
    };
    kernelModules = [ "kvm-intel" ];
    kernelParams =  [ "console=ttyS1,115200n8" ];
    extraModulePackages = [ ];
    loader = {
      grub = {
        zfsSupport = true;
      };
    };
  };

  hardware = {
    enableAllFirmware = true;
  };

  nix = {
    maxJobs = 48;
  };
}
