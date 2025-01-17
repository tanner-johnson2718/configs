# Module to wrap a gitea server with mkdocs support..

{config, lib, ...}:
let
  cfg = config.gitea-server;
in
{
  options = {
    gitea-server.enable = lib.mkEnableOption "Enable the gitea server module";
    gitea-server.sshPort = lib.mkOption { type = lib.types.port; };
    gitea-server.gitSshPort = lib.mkOption { type = lib.types.port; };
    gitea-server.httpPort = lib.mkOption { type = lib.types.port; };
    gitea-server.domain = lib.mkOption { type = lib.types.str; };
    gitea-server.sshLoginKey = lib.mkOption { type = lib.types.str; };
    gitea-server.hashedPassword = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkIf cfg.enable {
    services.gitea = {
      enable = true;
      stateDir = "/var/lib/gitea";

      # Dump is used to generate backups
      dump = {
	enable = true;
	type = "tar.gz";
	interval = "weekly";
	file = "gitea-bak.tar.gz";
      };

      settings = {
	session.COOKIE_SECURE = true;
	service.DISABLE_REGISTRATION = true;
	server.SSH_PORT = cfg.gitSshPort;
	server.PROTOCOL = "https";
	server.HTTP_PORT = cfg.httpPort;
	server.DOMAIN = cfg.domain;
	log.level = "Info";
      };  
    };

    services.openssh =
    {
      startWhenNeeded = true;
      settings.X11Forwarding = false;
      settings.UsePAM = false;
      settings.UseDns = false;
      settings.StrictModes = true;
      settings.PrintMotd = false;
      settings.PermitRootLogin = "prohibit-password";
      settings.PasswordAuthentication = false;
      settings.LogLevel = "INFO";
      settings.KbdInteractiveAuthentication = false;
      settings.GatewayPorts = "no";
      settings.AuthorizedPrincipalsFile = "none";
      settings.AllowUsers = [ "root" ];
      settings.AllowGroups = [ "root" ];
      ports = [ cfg.sshPort ];
      openFirewall = false;
      enable = true;
      banner = ''
===============================================================================
=                               GO AWAY                                       =
===============================================================================
      '';
      authorizedKeysInHomedir = false;
      allowSFTP = false;
    };

    users.users.root.hashedPassword = cfg.hashedPassword;
    users.mutableUsers = false;
    users.users."root".openssh.authorizedKeys.keys = [ cfg.sshLoginKey ];

    networking.firewall = 
    {
      enable = true;
      allowPing = false;
      rejectPackets = false;
      filterForward = false;
      allowedUDPPorts = lib.mkForce [];
      allowedTCPPorts = [ 
	cfg.sshPort
	cfg.gitSshPort
	cfg.httpPort
      ];
      checkReversePath = "strict";
      trustedInterfaces = lib.mkForce [];
      logRefusedPackets = true;
      logReversePathDrops = true;
      allowedUDPPortRanges = lib.mkForce [];
      allowedTCPPortRanges = lib.mkForce [];
      logRefusedUnicastsOnly = false;
      logRefusedConnections = true;
      autoLoadConntrackHelpers = false;
      connectionTrackingModules = lib.mkForce [];
    };
  };
}
