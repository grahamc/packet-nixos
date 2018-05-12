{
  boot.loader.grub.devices = [ "/dev/sda" ];

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
