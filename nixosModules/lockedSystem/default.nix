# Configure the users, ssh daemon, firewall, etc in strict manner such that
# the network attack surface is minimal. The following policies are implemented
# by this module:
# 
# TODO Verify all these
# - Root user with no password and ssh auth from a single key only
# - Only allow port 22 on ssh and port 80 HTTPS traffic
# - Disable all unneeded services
# - Try to get rid of unneeded users, groups, etc
# - Log all network traffic, logins, etc 
# - Do not allow loadable kernel module

{config, lib, ...}:
let
  cfg = config.lockedSystem;
in
{
  options = {
    lockedSystem.enable = lib.mkEnableOption "Enable Locked System Module";
    lockedSystem.sshKey = lib.mkOption { type = lib.types.str; };
  };    

  config = lib.mkIf cfg.enable {
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
      ports = [ 22 ];
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

    users.mutableUsers = false;
    users.users."root".openssh.authorizedKeys.keys = [ cfg.sshKey ];

    networking.firewall = 
    {
      enable = true;
      allowPing = false;
      rejectPackets = false;
      filterForward = false;
      allowedUDPPorts = lib.mkForce [];
      allowedTCPPorts = [ 22 80 ];
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
