{ lib, pkgs, config, ... }:

with lib;

let
  install-tools = (import ./install-tools { inherit pkgs; });
  cfg = config.installer;
in {

  options.installer = {
    runTimeNixOS = mkOption {
      description = ''
        A path of a NixOS system that closely resembles the final
        version of NixOS, so minimal building takes place on the
        target.

        To speed up the build.
      '';
      default = "";
      type = types.path;
    };

    kexec = mkOption {
      description = ''
        Don't do a full reboot, just load the new kernel and kexec it.
      '';
      default = false;
      type = types.bool;
    };

    configFiles = mkOption {
      description = "Config files to copy to the installed system";
      type = types.listOf types.path;
    };

    type = mkOption {
      description = "System Type";
      type = types.string;
    };

    partition = mkOption {
      description = "Partitioning commands";
      type = types.string;
    };
    format = mkOption {
      description = "Formatting commands";
      type = types.string;
    };
    mount = mkOption {
      description = "Mounting commands";
      type = types.string;
    };
  };

  config = {
    networking.hostName = "install-environment";

    # systemd.services.sshd.wantedBy = mkForce [ "multi-user.target" ];

    systemd.services.dumpkeys = {
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      script = ''
        if ${pkgs.gnugrep}/bin/grep -q debug-install /proc/cmdline; then
          mkdir /root/.ssh || true
          touch /root/.ssh/authorized_keys
          chmod 0644 /root/.ssh/authorized_keys
          ${install-tools}/bin/dump-keys.py > /root/.ssh/authorized_keys
          systemctl start sshd
        fi
      '';
    };

    systemd.services.doinstall = {
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      script = ''
        if ${pkgs.gnugrep}/bin/grep -q debug-install /proc/cmdline; then
          echo "Not running doinstall because debug-install was set"
          exit 1
        fi
        # ${cfg.runTimeNixOS} # Force realization & config validation
        . ${install-tools}/bin/tools.sh

        initialize

        pre_partition

        ${cfg.partition}

        pre_format

        ${cfg.format}

        pre_mount

        ${cfg.mount}

        post_mount

        generate_standard_config

        cp \
        ${lib.concatMapStrings
          (x: "  ${x} \\\n")
          cfg.configFiles
        } /mnt/etc/nixos/packet/

        finalize_config
        do_install
        ${if cfg.kexec then "do_kexec" else "do_reboot"}
      '';
      environment = {
        NIX_PATH = "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels";
        HOME = "/root";
      };
    };
  };
}
