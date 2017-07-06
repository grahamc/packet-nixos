{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  boot = {
    initrd = {
      availableKernelModules = [
        "ehci_pci" "ahci" "usbhid" "sd_mod"
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
    maxJobs = 4;
  };
}
