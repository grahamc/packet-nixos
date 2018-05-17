let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;
  filtered = lib.filterAttrs
    (name: sys: sys.system == "x86_64-linux")
    (import ./default.nix);
   ln = lib.mapAttrsToList (n: v: ''
     ln -s ${v} $out/${n}
     ln -s ${v} $out/${v.class}
   '') filtered;
in pkgs.runCommand "x86-pxe-images" {} ''
  mkdir -p $out
  ${lib.concatStringsSep "\n" ln}
''
