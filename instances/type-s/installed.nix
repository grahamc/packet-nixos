{
  boot.loader.grub.zfsSupport = true;
  boot.loader.grub.devices = [ "/dev/sdc" ];

  services.zfs.autoScrub.enable = true;

  fileSystems = {
    "/" = {
      device = "rpool/root";
      fsType = "zfs";
    };
  };
}
