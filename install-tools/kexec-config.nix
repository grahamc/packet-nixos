let
  config = (import <nixpkgs/nixos> {
    configuration = "/mnt/etc/nixos/configuration.nix";
  }).config;
in ''
kexec \
        -l "/mnt/${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}" \
        --initrd "/mnt/${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}" \
        --append="init=${builtins.unsafeDiscardStringContext config.system.build.toplevel}/init ${toString config.boot.kernelParams}"
''
