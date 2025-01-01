{...}:
{
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
    openFirewall = true;
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
  users.users."root".openssh.authorizedKeys.keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJB6woywk5BcJjvvlEvxaUNMaCMgqZlWSwVGOJkLg5Eq";


}
