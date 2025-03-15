# TODO I have a loose understanding of the dbus, look into it more and see how
# the apps that you use actually use the dbus
{ config, lib, pkgs, ...}:
let
  cfg = config.sway;
in
{
  options.sway = {
    enable = lib.mkEnableOption "Enable Sway Module"; 
  };

  config = lib.mkIf cfg.enable {
    # IDK what the consequences of this are but I don't want the gnome key vault
    services.gnome.gnome-keyring.enable = false;
    
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;

      # TODO until I know what I want, force wipe out the upstream default
      extraPackages = lib.mkForce [];
    };
  };
}
