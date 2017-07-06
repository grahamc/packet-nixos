{
  boot = {
    loader = {
      grub = {
        zfsSupport = true;
        devices = [
          "/dev/sdc"
        ];
      };
    };
  };

  services.zfs.autoScrub.enable = true;

  fileSystems = {
    "/" = {
      device = "rpool/root";
      fsType = "zfs";
    };
  };
}
