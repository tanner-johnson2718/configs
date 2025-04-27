# TODO export and declare dashboards
# TODO back up images of prom-db
# TODO add collectors under the 9100 node exporter

{pkgs, lib, config, ...}: 
let
  cfg = config.dashboard;
  ip = lib.mkOption {
    type = lib.types.str;
    default = "127.0.0.1";
  };
  port = p: lib.mkOption {
    type = lib.types.port;
    default = p;
  };
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
      inherit ip;
      port = port 9091;
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
    };

    prometheusServer = {
      inherit ip;
      port = port 9090;
      enable = lib.mkOption {
	type = lib.types.bool;
	default = false;
	example = "true";
	description = ''
	  Enable the main prometheus server and scrape services.
	'';
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
      inherit ip; 
      port = port 9100;
      enable = lib.mkOption {
	type = lib.types.bool;
	default = false;
	example = "true";
	description = ''
	   Enable systemd node exporter on this system. 
	'';
      };
    };

    grafana = {
      inherit ip;
      port = port 3000;
      enable = lib.mkOption {
	type = lib.types.bool;
	default = false;
	example = "true";
	description = ''
	  Enable the grafana server.
	'';
      };
    };

    fileExporter = {
      inherit ip;
      port = port 9101;
      enable = lib.mkOption {
	type = lib.types.bool;
	default = false;
	example = "true";
	description = ''
	  Enable file node exporter
	'';
      };
      rootDir = lib.mkOption {
	type = lib.types.str;
	default = "/var/metrics";	
      };
      package = lib.mkOption {
	type = lib.types.package;
	default = pkgs.stdenv.mkDerivation {
	  name = "file-node-exporter";
	  propagatedBuildInputs = [
	    (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
	      prometheus-client
	    ]))
	  ];
	  dontUnpack = true;
	   installPhase = "install -Dm755 ${./file-node-exporter.py} $out/bin/file-node-exporter";
	};
      };
      files = lib.mkOption {
	type = lib.types.listOf (lib.types.submodule {
	  options = {
	    metric = lib.mkOption {
	      type = lib.types.str;
	    };
	    type = lib.mkOption {
	      type = lib.types.enum [
		"counter"
		"gauge"
	      ];
	    };
	  };
	});
      };
    };
  };

  config = lib.mkIf cfg.enable {
    
    systemd.services.file-node-exporter = lib.mkIf cfg.fileExporter.enable {
      enable = true;
      serviceConfig = {
	ExecStart = "${cfg.fileExporter.package}/bin/* -a ${cfg.fileExporter.ip} -p ${toString cfg.fileExporter.port} -d ${cfg.fileExporter.rootDir}";
      };
    };

    systemd.tmpfiles.rules = lib.mkIf cfg.fileExporter.enable
      (map 
	(a: "f ${cfg.fileExporter.rootDir}/${toString cfg.fileExporter.port}/${a.type}/${a.metric}/value 0755 root root -")
	cfg.fileExporter.files);

    services.prometheus = {
      enable        = cfg.prometheusServer.enable;
      listenAddress = cfg.prometheusServer.ip;
      port          = cfg.prometheusServer.port;
      retentionTime = cfg.prometheusServer.retentionTime;
      scrapeConfigs = lib.mkIf cfg.prometheusServer.enable [
	  {
	    job_name = "scrape0";
	    scrape_interval = cfg.prometheusServer.scrapeInterval;
	    static_configs = [
	      {
		targets = [] 
		  ++ (lib.optionals cfg.pushgateway.enable [ "${cfg.pushgateway.ip}:${toString cfg.pushgateway.port}" ])
		  ++ (lib.optionals cfg.node.enable [ "${cfg.node.ip}:${toString cfg.node.port}" ])
		  ++ (lib.optionals cfg.fileExporter.enable [ "${cfg.fileExporter.ip}:${toString cfg.fileExporter.port}" ])
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
