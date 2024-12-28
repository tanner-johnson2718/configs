{config, lib, ...}:
let
  cfg = config.gnome;
in
{
  options = {
    gnome.enable = lib.mkEnableOption "Enable Gnome";
  };

  config = lib.mkIf cfg.enable {
    services = {
      xserver = { 
        videoDrivers = [ "nvidia" ];
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
        xkb = {
          layout = "us";
          variant = "";
        };
      };

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
    }; 
  };
}
