let
  pkgs = import <nixpkgs> {};
  pin_file = "${toString ./.}/nixpkgs.json";

  url = "https://github.com/nixos/nixpkgs-channels.git";
in rec {
  branch = "nixos-18.09";

  pinned = let
      src = builtins.fromJSON (builtins.readFile ./nixpkgs.json);
    in {
      inherit (src) url rev;
      ref = "${branch}";
    };

  update = pkgs.writeScript "update.sh" ''
    #!${pkgs.bash}/bin/bash

    set -euxo pipefail

    ${pkgs.nix-prefetch-git}/bin/nix-prefetch-git \
      "${url}" \
      --rev "refs/heads/${branch}" > "${pin_file}"
  '';
}
