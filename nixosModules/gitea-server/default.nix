# Module to wrap a gitea server with mkdocs support..

{config, lib, ...}:
let
  cfg = config.gitea-server;
in
{
  options = {
    gitea-server.enable = lib.mkEnableOption "Enable the gitea server module";
    gitea-server.sshPort = lib.mkOption { type = lib.types.port; };
    gitea-server.httpPort = lib.mkOption { type = lib.types.port; };
    gitea-server.domain = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkIf cfg.enable {
    services.gitea = {
      enable = true;
      stateDir = "/var/lib/gitea";

      # Dump is used to generate backups
      dump = {
	enable = true;
	type = "tar.gz";
	interval = "01:00";
	file = "gitea-bak.tar.gz";
      };

      settings = {
	session.COOKIE_SECURE = true;
	service.DISABLE_REGISTRATION = true;
	server.SSH_PORT = cfg.sshPort;
	server.PROTOCOL = "https";
	server.HTTP_PORT = cfg.httpPort;
	server.DOMAIN = cfg.domain;
	log.level = "Info";
      };
      
    };
  };
}
