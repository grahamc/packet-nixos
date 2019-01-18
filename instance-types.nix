let
  pkgs = import ./nix {};
  filtered = import ./default.nix;

  env = {
    NIX_PATH = "nixpkgs=${pkgs.path}";
  };

  mkStep = label: command:
    {
      inherit label command env;
    };
  mkWaitStep = "wait";
  mkBlockStep = label: {
    block = label;
  };

in
  pkgs.writeText "pipeline.yml"
    (builtins.toJSON {
      steps = [
        (mkStep "build-aarch64" "nix-build ./arm.nix --keep-going")
        (mkStep "build-x86-64" "nix-build ./x8664.nix --keep-going")
        mkWaitStep
        (mkStep "upload" ''echo "would upload :)";'')
        (mkBlockStep "Launch")
        ] ++
        (builtins.map
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
  )
