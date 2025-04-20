{pkgs, lib, config, ...}: 
let
  cfg = config.dashboard;
  wakeup-hour = 5;
  beddown-hour = 21;
in 
{
  options.dashboard = {

    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = "true";
      description = ''
	Enable the dashboard module. This is composed of three main components:

	  1) Grafana for visualization
	  2) Prometheus as a DB and Data Aggregator
	  3) Prometheus built in and custom node 
	     exporters for scraping data.
      '';
    };

    pushgateway = { 
      enable = lib.mkOption {
	type = lib.types.bool;
	default = false;
	example = "true";
	description = ''
	  Enable the pushgateway service. This creates a service that accepts
	  "pushes" in the form of an http request:

	    cat <<EOF | curl --data-binary @- http://pushgateway.example.org:9091/metrics/job/some_job/instance/some_instance
	      some_metric{label="val1"} 42
	      another_metric 2398.283
	    EOF
	'';
      };
      ip = lib.mkOption {
	type = lib.types.str;
	default = "127.0.0.1";
      };
      port = lib.mkOption {
	type = lib.types.port;
	default = 9091;
      };
    };

    prometheusServer = {
      enable = lib.mkOption {
	type = lib.types.bool;
	default = false;
	example = "true";
	description = ''
	  Enable the main prometheus server and scrape services.
	'';
      };
      ip = lib.mkOption {
	type = lib.types.str;
	default = "127.0.0.1";
      };
      port = lib.mkOption {
	type = lib.types.port;
	default = 9090;
      };
      scrapeInterval = lib.mkOption {
	type = lib.types.str;
	default = "1m";
      };
      additionalNodes = lib.mkOption {
	type = lib.types.listOf lib.types.str;
	default = [];
	example = "[ node_host:node_port ]";
      };
      retentionTime = lib.mkOption {
	type = lib.types.str;
	default = "30d";
      };
    };

    node = {
      enable = lib.mkOption {
	type = lib.types.bool;
	default = false;
	example = "true";
	description = ''
	   Enable systemd node exporter on this system. 
	'';
      };
      ip = lib.mkOption {
	type = lib.types.str;
	default = "127.0.0.1";
      };
      port = lib.mkOption {
	type = lib.types.port;
	default = 9100;
      };
    };

    grafana = {
      enable = lib.mkOption {
	type = lib.types.bool;
	default = false;
	example = "true";
	description = ''
	  Enable the grafana server.
	'';
      };
      ip = lib.mkOption {
	type = lib.types.str;
	default = "127.0.0.1";
      };
      port = lib.mkOption {
	type = lib.types.port;
	default = 3000;
      };
    };

  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.prometheus
    ];

    services.prometheus = {
      enable        = cfg.prometheusServer.enable;
      listenAddress = cfg.prometheusServer.ip;
      port          = cfg.prometheusServer.port;
      retentionTime = cfg.prometheusServer.retentionTime;
      scrapeConfigs = [
	  {
	    job_name = "scrape0";
	    scrape_interval = cfg.prometheusServer.scrapeInterval;
	    static_configs = [
	      {
		targets = [] 
		  ++ (lib.optionals cfg.pushgateway.enable [ "${cfg.pushgateway.ip}:${toString cfg.pushgateway.port}" ])
		  ++ (lib.optionals cfg.node.enable [ "${cfg.node.ip}:${toString cfg.node.port}" ])
		  ++ cfg.prometheusServer.additionalNodes;
	      }
	    ];
	  }
	];

	pushgateway = { 
	  enable = cfg.pushgateway.enable;
	  extraFlags = [ "--web.listen-address ${cfg.pushgateway.ip}:${toString cfg.pushgateway.port}" ];
	};
	
	exporters = {
	  node = {
	    enable = cfg.node.enable;
	    port = cfg.node.port;
	    enabledCollectors = [ "systemd" ];
	    listenAddress = cfg.node.ip;
	  };
	};
	
    };

    services.grafana = {
      enable = cfg.grafana.enable;
      settings = {
	server.http_addr = cfg.grafana.ip;
	server.http_port = cfg.grafana.port;
      };
      provision = {
	enable = cfg.grafana.enable;
	datasources.settings.datasources = [
	  {
	    name = "prometheus";
	    isDefault = true;
	    type = "prometheus";
	    url = "http://${cfg.prometheusServer.ip}:${toString cfg.prometheusServer.port}";
	  }
	];
      };
    };
  };
}
