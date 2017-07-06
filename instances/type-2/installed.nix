{
  boot = {
    loader = {
      grub = {
        devices = [
          "/dev/sda" "/dev/sdb" "/dev/sdc" "/dev/sdd" "/dev/sde"
          "/dev/sdf"
        ];
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "rpool/root/nixos";
      fsType = "zfs";
    };
  };
}
