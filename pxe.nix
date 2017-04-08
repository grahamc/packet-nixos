{ lib, pkgs, config, ... }:

with lib;

let
  image = pkgs.runCommand "image" { buildInputs = [ pkgs.nukeReferences ]; } ''
    mkdir $out
    cp ${config.system.build.kernel}/bzImage $out/kernel
    cp ${config.system.build.netbootRamdisk}/initrd $out/initrd
    nuke-refs $out/kernel
  '';

  install-tools = (import ./install-tools {});
in {
  imports = [ <nixpkgs/nixos/modules/installer/netboot/netboot-minimal.nix> ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelParams = [ "console=ttyS1,115200n8" ];
  networking.hostName = "ipxe";

  system.activationScripts.do-install = ''
    echo ${install-tools}/bin/try-try-again.sh ${install-tools}/bin/dispatch.py >> /root/.profile
  '';
}
