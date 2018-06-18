{ lib, ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub = {
        enable = true;
        font = null;
        splashImage = null;
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
      label = "nixos";
      fsType = "ext4";
    };
    "/boot/efi" = {
      label = "boot";
      fsType = "vfat";
    };
  };
}
