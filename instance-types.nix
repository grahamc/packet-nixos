let
  pkgs = import ./nix {};
  filtered = import ./default.nix;
in pkgs.writeText "pipeline.yml"
  (builtins.toJSON {
    steps = (builtins.map
      (x: {
        command = ''
          cd ./expect-tests
          echo ". /etc/packet-nixos-config" > ./config.sh
          ./create.sh ${x.class}
        '';
        label = "${x.class}";
        env = {
          NIX_PATH = "nixpkgs=${pkgs.path}";
        };
      })
      (builtins.attrValues filtered));
  }
)
