{ pkgs, ... }:
{
  systemd.services.boot-phone-home = {
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" "network-online.target" ];
    unitConfig.ConditionPathExists = "/etc/.packet-phone-home";
    path = [ pkgs.curl ];
    script = ''
      set -x
      set +e
      for i in $(seq 1 30); do
        echo "Attempt $1 to tell Packet we're up..."
        CURL_CALL
        if [ $? = 0 ]; then
          rm /etc/.packet-phone-home
          exit 0
        fi
        sleep "$i"
      done

    '';
  };
}
