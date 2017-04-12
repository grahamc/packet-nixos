{ lib, pkgs, config, ... }:
{
  imports = [
    ./base.nix
  ];
  boot.kernelParams = [ "console=ttyS1,115200n8" ];
}
