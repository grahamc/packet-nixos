let
  pkgs = import ./nix {};
  filtered = import ./default.nix;

  env = {
    NIX_PATH = "nixpkgs=${pkgs.path}";
  };
in {
  build = pkgs.writeText "pipeline.yml"
    (builtins.toJSON {
      steps = [{
        command = ''
          nix-build ./default.nix --keep-going
          nix-build ./default.nix --keep-going
          ./build-pipeline.sh upload
        '';
        label = "build";
      }];
    });

  upload = pkgs.writeText "pipeline.yml"
    (builtins.toJSON {
      steps = [{
        command = ''
          echo "would upload :)"
          exit 1
          ./build-pipeline.sh launch
        '';
        label = "build";
      }];
    });

  launch = pkgs.writeText "pipeline.yml"
    (builtins.toJSON {
      steps = (builtins.map
        (x: {
          command = ''
            cd ./expect-tests
            echo ". /etc/packet-nixos-config" > ./config.sh
            ./create.sh ${x.class}
          '';
          label = "${x.class}";
          inherit env;
        })
        (builtins.attrValues filtered));
    }
  );
}
