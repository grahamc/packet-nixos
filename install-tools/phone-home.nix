{
  systemd.services.boot-phone-home = {
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "/etc/.packet-phone-home"
    script = ''
      @out@/bin/notify.py installed
      rm /etc/.packet-phone-home
    '';
  };
}
