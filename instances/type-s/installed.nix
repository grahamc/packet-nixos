{
  boot.loader.grub.devices = [ "/dev/sdo" ];

  fileSystems = {
    "/" = {
      label = "nixos";
      fsType = "ext4";
    };
  };

  swapDevices = [
    {
      label = "swap";
    }
  ];
}
