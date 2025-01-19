# Module to wrap a gitea server with mkdocs support..

{config, lib, pkgs, ...}:
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
    environment.systemPackages = with pkgs; [
      lsof
    ];

    services.gitea = {
      enable = true;
      settings = {
	server.SSH_PORT = cfg.gitSshPort;
	server.HTTP_PORT = 3001;
      };  
    };

    #services.nginx = {
    #  enable = true;    
    #  virtualHosts."${cfg.domain}" = {
    #    locations."/".proxyPass = "http://localhost:3001/";
    #  };
    #};

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
      enable = false;
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
