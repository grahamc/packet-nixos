{ lib, ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub = {
        enable = true;
        extraConfig = ''
          serial
          terminal_input serial console
          terminal_output serial console
        '';
      };
      efi = {
        efiSysMountPoint = "/boot/efi";
        canTouchEfiVariables = lib.mkForce false;
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/sda2";
      fsType = "ext4";
    };
    "/boot/efi" = {
      device = "/dev/sda1";
      fsType = "vfat";
    };
  };
}
