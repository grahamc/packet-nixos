let
  config = import ./config.nix;
  nixpkgs = builtins.fetchGit config.pinned;
in import nixpkgs
