let
  arm = import ./arm.nix;
  x86 = import ./x8664.nix;

  pkgs = import <nixpkgs> {};
in pkgs.buildEnv {
  name = "all-pxe-images";
  paths = [ x86 arm ];
}
