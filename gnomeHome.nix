{pkgs,config,...}: {
  home.packages = with pkgs; [
    gnomeExtensions.freon
  ];

    #############################################################################
    # Dconf
    ############################################################################# 

    dconf.settings = {
      "org/gnome/desktop/background" = {
        picture-uri = "file:///${config.home.homeDirectory}/.background-image";
        picture-uri-dark = "file:///${config.home.homeDirectory}/.background-image";
        color-shading-type = "solid";
        picture-options = "zoom";
        primary-color = "#000000000000";
        secondary-color = "#000000000000";
      };
      "org/gnome/desktop/screensaver" = {
        picture-uri = "file:///${config.home.homeDirectory}/.background-image";
        picture-uri-dark = "file:///${config.home.homeDirectory}/.background-image";
        color-shading-type = "solid";
        picture-options = "zoom";
        primary-color = "#000000000000";
        secondary-color = "#000000000000";
      };
      "org/gnome/desktop/interface" = { 
        color-scheme = "prefer-dark";
        show-battery-percentage = true;
      };
      "org/gtk/gtk4/settings/file-chooser" = {
        show-hidden = true;
      };
      "org/gnome/desktop/wm/keybindings" = {
        activate-window-menu = ["<Alt>slash"];
      };
      "org/gnome/desktop/input-sources" = {
        xkb-options = ["ctrl:nocaps"];
      };
      "org/gnome/shell" = {
        favorite-apps = [
          "kitty.desktop"
          "google-chrome.desktop" 
        ];
        disable-user-extensions = false;
        enabled-extensions = [
          "freon@UshakovVasilii_Github.yahoo.com"
        ];
        last-selected-power-profile = "power-saver";
      };
      "org/gnome/shell/extensions/freon" = {
        hot-sensors = [ "BAT0 Power" "__max__" ];
      };
      "org/gnome/desktop/peripherals/touchpad" = {
        speed = 1.0;
      };
    };
}
