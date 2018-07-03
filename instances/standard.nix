{
  boot.kernelModules = [ "dm_multipath" "dm_round_robin" "ipmi_watchdog" ];
  services.openssh.enable = true;
}
