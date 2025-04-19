{pkgs, lib, config, ...}: 
let
  cfg = config.dashboard;
in 
{

  options.dashboard = {
    enable = lib.mkEnableOption "Enable dashboard module";
    pushgatewayIP = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
    };
    pushgatewayPort = lib.mkOption {
      type = lib.types.port;
      default = 9091;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      prometheus = {
	enable = true;
	pushgateway = { 
	  enable = true;
	  extraFlags = [ "--web.listen-address ${toString cfg.pushgatewayPort}" ];
	};
	retentionTime = "30d";
	scrapeConfigs = [
	  {
	    job_name = "scrape_push";
	    scrape_interval = "1m";
	    static_configs = [
	      {
		targets = [ "${cfg.pushgatewayIP}:${toString cfg.pushgatewayPort}" ];
	      }
	    ];
	  }
	];
      };
    };
  };
}
