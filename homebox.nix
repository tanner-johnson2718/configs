# homebox.nix - nixos system config for my asus gu603 gaming laptop.

# TODO gamebox0 -> homebox
# TODO Better control and measuring of power draw
# TODO Asus FW?
# TODO FDE
# TODO suspend doesnt work properly
# TODO back up promDB and grafana
# TODO how do I add custom collectors?
# TODO verify that after 30d promDB entries get cleared

{config, lib, pkgs, inputs, modulesPath, ...}:
let
  user            = "gamebox0";
  hashedPassword  = "$y$j9T$IBmfxiN89ruEnbsSZEdVY/$KfBV6TLSYhuPo6Q/JLEMJZMhi5yjJUPUA/3KTz8rdmD";
  yubiID          = "29490434";
  prometheusDbIp        = "127.0.0.1";
  prometheusDbPort      = 9090;
  prometheusDbRetention = "30d";
  prometheusNodeIp      = "127.0.0.1";
  prometheusNodePort    = 9100; 
  grafanaIp             = "127.0.0.1";
  grafanaPort           = 3000;
in
{
  imports = [ 
    inputs.home-manager.nixosModules.default
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  config = {
    programs.steam = {
      enable = true;
      extraCompatPackages = with pkgs; [proton-ge-bin];
    };

    environment.systemPackages = with pkgs; [
      google-chrome
      yubioath-flutter
      qbittorrent
      freecad
      vlc
      atlauncher
    ];

    ###########################################################################
    # Nix Daemon, Nixpkgs, Homemanager and Users
    ###########################################################################
    
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = ".bak";
      extraSpecialArgs = { inherit inputs; };
      users."${user}" = ({...}: {
        imports = [ ./home.nix ]; 
        config = {
          home.username = user;
          home.homeDirectory = "/home/${user}";
          home.stateVersion = "24.11";
	  programs.home-manager.enable = true;
        };
      });
    };

    nix = {
      settings = { 
	experimental-features = [ "nix-command" "flakes" ];
	trusted-users = [ "root" "${user}" ];
      };
    };

    nixpkgs = {
      config.allowUnfree = true;
      config.allowBroken = true;
      hostPlatform = "x86_64-linux";
      system = "x86_64-linux";
    };

    system.stateVersion = "24.11";

    users.mutableUsers = false; 
    users.users."${user}" = {
      inherit hashedPassword;
      isNormalUser = true;
      description = user;
      extraGroups = [ "networkmanager" "wheel" "dialout" ];
    };

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

    ###########################################################################
    # Networking
    ###########################################################################
  
    networking.networkmanager.enable = lib.mkDefault true;
    networking.hostName              = lib.mkDefault user;
 
    ###########################################################################
    # Hardware (CPU)
    ###########################################################################

    fileSystems = {
      "/" = { 
        device = "/dev/disk/by-uuid/3f986e0c-dd3e-42d8-8693-c46c02c06e94";
        fsType = "ext4";
      };
      "/boot" = { 
        device = "/dev/disk/by-uuid/1ED3-74FC";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };
    };

    boot = {
      kernelPackages = pkgs.linuxPackages_6_12;
      initrd.availableKernelModules = [ 
	"xhci_pci" 
	"thunderbolt" 
	"vmd" 
	"nvme"
	"usbhid"
	"usb_storage" 
	"sd_mod" 
	"sdhci_pci"
      ];
      initrd.kernelModules = [ ];
      kernelModules = [ "kvm-intel" ];
      extraModulePackages = [ ];
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };

    hardware.cpu.intel.updateMicrocode = true;

    powerManagement = {
      enable = true;
      cpuFreqGovernor = "performance";
      cpufreq = {
	min = null;
	max = null;
      };
      scsiLinkPolicy = "max_performance";
      powertop.enable = false;      

      resumeCommands = "";
      powerUpCommands = "";
      powerDownCommands = "";
    };

    ###########################################################################
    # Hardware (GPU)
    ###########################################################################

    hardware = {
      
      nvidiaOptimus.disable = false;
      graphics.enable = true;

      nvidia = {
        package             = config.boot.kernelPackages.nvidiaPackages.stable;
        open                = false;
        modesetting.enable  = true;
        nvidiaSettings      = true;
	dynamicBoost.enable = false;
	nvidiaPersistenced  = false;
	gsp.enable          = true;

	forceFullCompositionPipeline = false;

        powerManagement = {
          enable = true;
          finegrained = true;
        };

        prime = {
	  sync.enable              = false;
          offload.enable           = true;
          offload.enableOffloadCmd = true;
	  allowExternalGpu         = false;
          intelBusId               = "PCI:0:2:0";
          nvidiaBusId              = "PCI:1:0:0";
	  reverseSync = {
	    enable = false;
	    setupCommands.enable = true;
	  };
        };
      };
    };

    ###########################################################################
    # Yubi Key
    # Note to get serial number run 'nix-shell -p yubico-pam -p yubikey-manager' 
    # followed by ykman list.
    #
    # Next run the following to save your key:
    #  1) nix-shell -p pam_u2f
    #  2) mkdir -p ~/.config/Yubico
    #  3) pamu2fcfg > ~/.config/Yubico/u2f_keys
    #
    # Next configure the key to use OTP
    #  1) nix-shell -p yubico-pam -p yubikey-manager
    #  2) ykman otp chalresp --touch --generate 2
    #  3) ykpamcfg -2 -v
    ###########################################################################

    security.pam.yubico = {
      enable = true;
      debug = true;
      mode = "challenge-response";
      id = [ yubiID ];
      control = "sufficient";
    };

    services.pcscd.enable = true;

    ###########################################################################
    # GNOME
    ###########################################################################

    services = {
      xserver = { 
        videoDrivers = lib.mkDefault [ "nvidia" ];
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

      gnome.gnome-keyring.enable = lib.mkForce false;
    };

    environment.gnome.excludePackages = with pkgs; [
      orca
      evince
      # file-roller
      geary
      gnome-disk-utility
      # seahorse
      # sushi
      # sysprof
      #
      # gnome-shell-extensions
      #
      # adwaita-icon-theme
      # nixos-background-info
      gnome-backgrounds
      # gnome-bluetooth
      # gnome-color-manager
      # gnome-control-center
      # gnome-shell-extensions
      gnome-tour # GNOME Shell detects the .desktop file on first log-in.
      gnome-user-docs
      # glib # for gsettings program
      # gnome-menus
      # gtk3.out # for gtk-launch program
      # xdg-user-dirs # Update user dirs as described in https://freedesktop.org/wiki/Software/xdg-user-dirs/
      # xdg-user-dirs-gtk # Used to create the default bookmarks
      #
      baobab
      epiphany
      gnome-text-editor
      gnome-calculator
      gnome-calendar
      gnome-characters
      # gnome-clocks
      gnome-console
      gnome-contacts
      gnome-font-viewer
      gnome-logs
      gnome-maps
      gnome-music
      # gnome-system-monitor
      gnome-weather
      # loupe
      # nautilus
      gnome-connections
      simple-scan
      # snapshot
      totem
      yelp
      gnome-software
    ];

    ###########################################################################
    # Dashboard
    ###########################################################################

    services.prometheus = {
      enable        = true;
      listenAddress = prometheusDbIp;
      port          = prometheusDbPort;
      retentionTime = prometheusDbRetention;
      scrapeConfigs = [
	{
	  job_name = "high_freq";
	  scrape_interval = "1m";
	  static_configs = [ {targets = ["${prometheusNodeIp}:${prometheusNodePort}"];} ];
	}
      ];

      exporters = {
	node = {
	  enable = true;
	  listenAddress = prometheusNodeIp;
	  port = prometheusNodePort;
	  enabledCollectors = [ 
	    "systemd"
	    "processes"
	    "interrupts"
	    "tcpstat"
	  ];
	};
      };
    };

    services.grafana = {
      enable = true;
      settings = {
	server.http_addr = grafanaIp;
	server.http_port = grafanaPort;
      };
      provision = {
	enable = true;
	datasources.settings.datasources = [
	  {
	    name = "prometheus";
	    isDefault = true;
	    type = "prometheus";
	    url = "http://${prometheusDbIp}:${toString prometheusDbPort}";
	  }
	];
      };
    };
  };
}
