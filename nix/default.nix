let
  rev = "49a6964a4250d98644da61f24dcc11ee0b28c4f9";
in import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
})
