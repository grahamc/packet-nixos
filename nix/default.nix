let
  rev = "49a6964a4250d98644da61f24dcc11ee0b28c4f9";
in builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    sha256 = "00bddri0620q67mrkfhwadwlxp14hz7qjkjymm5z9s2wpwar4r26";
}
