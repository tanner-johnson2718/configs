# TODO export and declare dashboards (i.e. grafan backup)
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

    enable = lib.mkEnableOption ''
	Enable the dashboard module. This is composed of three main components:

	  1) Grafana for visualization
	  2) Prometheus as a DB and Data Aggregator
	  3) Prometheus built in and custom node 
	     exporters for scraping data.

	As of right now the suggested use of this module is as follows.
      '';

    pushgateway = {
      inherit ip;
      port = port 9091;
      enable = lib.mkEnableOption ''
	  !!! WARNING Depricated in favor of the postExporter !!!

	  Enable the pushgateway service. This creates a service that accepts
	  "pushes" in the form of an http request:

	    cat <<EOF | curl --data-binary @- http://pushgateway.example.org:9091/metrics/job/some_job/instance/some_instance
	      some_metric{label="val1"} 42
	      another_metric 2398.283
	    EOF
	'';
    };

    prometheusServer = {
      inherit ip;
      port = port 9090;
      enable = lib.mkEnableOption ''
	  Enable the main prometheus server and scrape services.
	'';
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

    systemExporter = {
      inherit ip; 
      port = port 9100;
      enable = lib.mkEnableOption ''
	   Enable the "default" node exporter and enble the systemd node collector.
	   This exporter is intended to capture system metrics and data. If it
	   relates to system health it should be exported via this exporter.
	'';
    };

    grafana = {
      inherit ip;
      port = port 3000;
      enable = lib.mkEnableOption ''
	Enable the grafana server.
      '';
    };

    postExporter = {
      inherit ip;
      port = port 9101;
      enable = lib.mkEnableOption ''
	Enable post node exporter. This node exporter is intended to replace the 
	pushgateway. It is intended to be bound to the systems localhost ip, allowing
	userspace i.e. non system metrics to be posted on the system. To use it

	  1) Declare it in postExporter.metrics, choosing its type and name. This
	     will create a file under the root dir :
	     
		/var/metrics/<postExporter port>/<metric type><metric name>/value

	     For now we assume no labels and that value will be the only file in the
	     metric dir.

	  2) Anybody on the system can now post to that metric (assuming the defaults) 
	     by executing:

	        curl -X POST 127.0.0.1:9101/metrics/<metric> -d "<value>"

	     The interpetation of value will be done based on the metrics type.
	     Counters this will be interpeted as inc and on a gauge a set. Failure
	     to provide a value is an error.

	  3) On updates the value of the will be written to "value" in the metric's 
	     dir
      '';
      rootDir = lib.mkOption {
	type = lib.types.str;
	default = "/var/metrics";	
      };
      metricPrefix = lib.mkOption {
	type = lib.types.str;
	default = "post";
      };
      package = lib.mkOption {
	type = lib.types.package;
	default = pkgs.stdenv.mkDerivation {
	  name = "post-exporter";
	  propagatedBuildInputs = [
	    (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
	      prometheus-client
	    ]))
	  ];
	  dontUnpack = true;
	   installPhase = "install -Dm755 ${./post-exporter.py} $out/bin/post-exporter";
	};
      };
      metrics = lib.mkOption {
	type = lib.types.listOf (lib.types.submodule {
	  options = {
	    name = lib.mkOption {
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
    
    systemd.services.file-node-exporter = lib.mkIf cfg.postExporter.enable {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      unitConfig = {
        Type = "simple";
      };
      serviceConfig = {
	ExecStart = ''
	  ${cfg.postExporter.package}/bin/post-exporter \
	    -a ${cfg.postExporter.ip} \ 
	    -p ${toString cfg.postExporter.port} \
	    -d ${cfg.postExporter.rootDir}/${toString cfg.postExporter.port}
	    -r ${cfg.postExporter.metricPrefix}
	'';
      };
    };

    systemd.tmpfiles.rules = lib.mkIf cfg.postExporter.enable
      (map 
	(a: "f ${cfg.postExporter.rootDir}/${toString cfg.postExporter.port}/${a.type}/${a.name}/value 0755 root root -")
	cfg.postExporter.metrics);

    services.prometheus = lib.mkIf cfg.enable {
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
		  ++ (lib.optionals cfg.systemExporter.enable [ "${cfg.systemExporter.ip}:${toString cfg.systemExporter.port}" ])
		  ++ (lib.optionals cfg.postExporter.enable [ "${cfg.postExporter.ip}:${toString cfg.postExporter.port}" ])
		  ++ cfg.prometheusServer.additionalNodes;
	      }
	    ];
	  }
	];

	pushgateway = lib.mkIf cfg.pushgateway.enable { 
	  enable = cfg.pushgateway.enable;
	  extraFlags = [ "--web.listen-address ${cfg.pushgateway.ip}:${toString cfg.pushgateway.port}" ];
	};
	
	exporters = lib.mkIf cfg.systemExporter.enable {
	  node = {
	    enable = cfg.systemExporter.enable;
	    port = cfg.systemExporter.port;
	    enabledCollectors = [ "systemd" ];
	    listenAddress = cfg.systemExporter.ip;
	  };
	};
    };

    services.grafana = lib.mkIf cfg.grafana.enable {
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
