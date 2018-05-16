{ pkgs ? import <nixpkgs> {}}:
let
  python3 = (pkgs.python3.withPackages (ps: [ ps.requests ]));

  packetconfiggen = pkgs.stdenv.mkDerivation rec {
    name = "packetconfiggen";
    src = ./metadata2hardware.py;

    python = python3;

    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out/bin
      echo "#!${python}/bin/python3" > $out/bin/packet-config-gen
      cat $src >> $out/bin/packet-config-gen
      chmod +x $out/bin/packet-config-gen
    '';
  };

  dumpkeys = pkgs.stdenv.mkDerivation rec {
    name = "dumpkeys";
    src = ./metadata2hardware.py;

    python = python3;

    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out/bin
      echo "#!${python}/bin/python3" > $out/bin/packet-config-gen
      cat $src >> $out/bin/packet-config-gen
      chmod +x $out/bin/packet-config-gen
    '';
  };
in pkgs.stdenv.mkDerivation {
  name = "installtools";
  src = ./bin;

  inherit (pkgs) coreutils utillinux e2fsprogs zfs;
  inherit packetconfiggen python3;
  phonehomeconf = ./phone-home.nix;

  buildPhase = ''
    substituteAllInPlace ./notify.py
    substituteAllInPlace ./dump-keys.py
    substituteAllInPlace ./tools.sh
  '';

  installPhase = ''
    ! grep -r "@" .

    mkdir -p $out/bin
    cp -r . $out/bin
    chmod +x $out/bin/*.sh
    chmod +x $out/bin/*.py
  '';
}
