{ lib, pkgs, config, ... }:

with lib;

let
  install-tools = (import ./install-tools {});
in {
  imports = [ <nixpkgs/nixos/modules/installer/netboot/netboot-minimal.nix> ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelParams = [ "console=ttyS1,115200n8" ];
  networking.hostName = "ipxe";

  systemd.services.sshd.wantedBy = mkForce [ "multi-user.target" ];

  systemd.services.dumpkeys = {
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    script = ''
      mkdir /root/.ssh || true
      touch /root/.ssh/authorized_keys
      chmod 0644 /root/.ssh/authorized_keys
      ${install-tools}/bin/dump-keys.py > /root/.ssh/authorized_keys
    '';
  };

  systemd.services.doinstall = {
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    script = "${install-tools}/bin/dispatch.py";
    environment = {
      NIX_PATH = "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels";
      HOME = "/root";
    };
  };

  #system.activationScripts.do-install = ''
  #  echo "echo ${install-tools}/bin/dispatch.py" >> /root/.profile
  #  echo "echo 'tail -f ./installer.log'" >> /root/.profile
  #'';
}
