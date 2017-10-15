{ config, lib, pkgs, ... }:
{
  boot.loader.grub.devices = [ "/dev/sda" "/dev/sdb" ];

  services.zfs.autoScrub.enable = true;

  fileSystems = {
    "/" = {
      device = "rpool/root/nixos";
      fsType = "zfs";
    };
  };
}
