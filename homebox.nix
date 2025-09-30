# homebox.nix - nixos system config for my asus gu603 gaming laptop.

# TODO Better control and measuring of power draw
# TODO Asus FW?
# TODO suspend doesnt work properly

{config, lib, pkgs, inputs, ...}:
let
  user            = "homebox";
  hashedPassword  = "$y$j9T$IBmfxiN89ruEnbsSZEdVY/$KfBV6TLSYhuPo6Q/JLEMJZMhi5yjJUPUA/3KTz8rdmD";
  yubiID          = "29490434";
in
{
  imports = [ 
    inputs.home-manager.nixosModules.default
    inputs.self.nixosModules.gnome
  ];

  config = {

    ###########################################################################
    # Do you have games on your phone
    ###########################################################################

    programs.steam = {
      enable = true;
      extraCompatPackages = with pkgs; [proton-ge-bin];
    };

    ###########################################################################
    # Nix Daemon, Nixpkgs, Homemanager and Users
    ###########################################################################

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = ".bak";
      extraSpecialArgs = { inherit inputs; };
      users."${user}" = ({...}: {
        imports = [ 
          inputs.self.homeModules.home
          inputs.self.homeModules.gnomeHome
        ]; 
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
        device = "/dev/disk/by-uuid/b58c2c94-e702-41e5-9d14-36d1d6502f8e";
        fsType = "ext4";
      };
      "/boot" = { 
        device = "/dev/disk/by-uuid/8A99-3B34";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };
    };

    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
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
      initrd.luks.devices."luks-b22281d7-b2d0-4031-90a9-958f6d95b034".device = "/dev/disk/by-uuid/b22281d7-b2d0-4031-90a9-958f6d95b034";
      kernelParams = [];
    };

    hardware.cpu.intel.updateMicrocode = true;
    hardware.enableRedistributableFirmware = true;
    hardware.enableAllFirmware = true;
    hardware.enableAllHardware = true;

    powerManagement = {
      enable = true;
      cpuFreqGovernor = "powersave";
      cpufreq = {
        min = null;
        max = null;
      };

      scsiLinkPolicy = "min_power";
      powertop.enable = false;
    };

    ###########################################################################
    # Hardware (GPU)
    ###########################################################################
    services.xserver.videoDrivers = [ "intel" ];
    hardware = {
      nvidiaOptimus.disable = true;
      graphics.enable = true;

      nvidia = {
        package             = config.boot.kernelPackages.nvidiaPackages.stable;
        open                = false;
        modesetting.enable  = false;
        nvidiaSettings      = true;
        nvidiaPersistenced  = false;
        forceFullCompositionPipeline = false;

        powerManagement = {
          enable = false;
          finegrained = false;
        };

        prime = {
          sync.enable = false;
          intelBusId  = "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    };

    boot.extraModprobeConfig = ''
  blacklist nouveau
  options nouveau modeset=0
'';
  
services.udev.extraRules = ''
  # Remove NVIDIA USB xHCI Host Controller devices, if present
  ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"
  # Remove NVIDIA USB Type-C UCSI devices, if present
  ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"
  # Remove NVIDIA Audio devices, if present
  ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
  # Remove NVIDIA VGA/3D controller devices
  ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
'';
boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" ];

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
  };
}
