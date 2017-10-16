{
  networking.firewall.allowedTCPPorts = [ 80 ];
  services.nginx = {
    enable = true;
    virtualHosts = {
      "test-root" = {
        default = true;
	root = ./nginx-root;
	extraConfig = ''
	  autoindex on;
	'';
      };
    };
  };
}
