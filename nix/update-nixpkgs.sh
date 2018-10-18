#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-prefetch-git

nix-prefetch-git https://github.com/nixos/nixpkgs-channels.git \
                 --rev refs/heads/nixos-18.09 > ./nix/nixpkgs.json
