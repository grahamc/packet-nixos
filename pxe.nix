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
  users.users.root.openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDTZB6tOYfEmWkYff494DjPpzo45ymhTvEPT4rjPyeTfBB1p+odbaVnYFQPgwk4MYBZyPjzQa9NLC76m2kCDNqnasBFGhTLxSfR9q/4J5G9x0a5NvA/emqNpjtbT25UADjhEETOIYjLYdd7z9rGFr/8ttmJNog6t9NIEw7/ddupzpvNaK80rdPSO7jt4/3TxFiix3yvaTNe4XahCiEDNIXF0hskOTuFtUX4LgiET9lmJa92i/Oh/7oYxDBond6C95HyoppGJu6y3txutAWt12N5rLRzWSPECwrJRNcXIqmIjofl+pt4vd7D4DHCxesKajG4fAs+KXZ3Lxug2dZB0eD grahamc@nixos" ];

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
