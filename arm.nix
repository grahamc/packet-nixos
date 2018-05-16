let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;
  filtered = lib.filterAttrs
    (name: sys: sys.system == "aarch64-linux")
    (import ./default.nix);
  ln = lib.mapAttrsToList (n: v: "ln -s ${v} $out/${n}") filtered;
in pkgs.runCommand "arm-pxe-images" {} ''
  mkdir -p $out
  ${lib.concatStringsSep "\n" ln}
''
