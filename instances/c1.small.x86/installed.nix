{
  boot.loader.grub.devices = [ "/dev/sda" "/dev/sdb" ];

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
