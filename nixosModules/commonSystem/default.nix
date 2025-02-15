# Common System module that sets up a nixos system with the following properties:
#
# - Enable flakes
# - Allow unfree
# - Single user system where the hostname is user name
# - timezone set
# - enable guard home manager
# - pass through inputs to homemanager
# - users passes a home manager cfg that configs hm to their liking

{config, lib, inputs, ...}:
let
  cfg = config.commonSystem;
in
{
  options = {
    commonSystem.enable = lib.mkEnableOption "Enable nixos common";
    commonSystem.userName = lib.mkOption { type = lib.types.str; };
    commonSystem.sshKey = lib.mkOption { type = lib.types.str; };
    commonSystem.hashedPassword = lib.mkOption { type = lib.types.str; };
    commonSystem.home-manager-enable = lib.mkEnableOption "Enable home manager common";
    commonSystem.home-manager-config = lib.mkOption {};
  };

  imports = [ inputs.home-manager.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.settings.trusted-users = [ "root" "${cfg.userName}" ];
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.allowBroken = true;
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

    users.mutableUsers = false; 
    users.users."${cfg.userName}" = {
      isNormalUser = true;
      description = "Mono User";
      extraGroups = [ "networkmanager" "wheel" "dialout" ];
      hashedPassword = cfg.hashedPassword;
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
