# Common module to set some dumb stuff that should just be fucking default i.e.
# allow unfree and flakes. This is more opionated but I also believe this 
# should just be default, but set up the plumbing so that home manager modules
# that are declared under homeModules and exposed at the flake level are 
# actually in scope for my nixosConfigs to access and pass to this module via
# the home-manager-config option. This module also enforces a mono user system 
# where the username, host name, and  nixos system name are all the same, 
# ideally derived from the name of the dir that the system config is contained in.

{config, lib, inputs, ...}:
let
  cfg = config.common;
in
{
  options = {
    common.enable = lib.mkEnableOption "Enable nixos common";
    common.userName = lib.mkOption { type = lib.types.str; };
    common.home-manager-enable = lib.mkEnableOption "Enable home manager common";
    common.home-manager-config = lib.mkOption {};
  };

  imports = [ inputs.home-manager.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.settings.trusted-users = [ "root" "${cfg.userName}" ];
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "24.11";
    
    networking.networkmanager.enable = lib.mkDefault true;
    networking.hostName              = lib.mkDefault cfg.userName; 

    time.timeZone = "America/Los_Angeles";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

     users.users."${cfg.userName}" = {
      isNormalUser = true;
      description = "Mono User";
      extraGroups = [ "networkmanager" "wheel" "dialout" ];
    };

    home-manager = lib.mkIf cfg.home-manager-enable {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = ".bak";
      extraSpecialArgs = { inherit inputs; };
      users."${cfg.userName}" = ({...}: {
        imports = [ cfg.home-manager-config ]; 
        config = {
          home.username = cfg.userName;
          home.homeDirectory = "/home/${cfg.userName}";
          home.stateVersion = "24.11";
	  programs.home-manager.enable = true;
        };
      });
    };
  };
}
