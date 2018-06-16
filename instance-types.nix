let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;
  filtered = import ./default.nix;
in pkgs.writeText "pipeline.yml"
  (builtins.toJSON {
    steps = (builtins.map
      (x: {
        command = "cd ./expect-tests; ./create.sh ${x.class}";
        label = "Testing image ${x.class}";
      })
      (builtins.attrValues filtered));
  }
)
