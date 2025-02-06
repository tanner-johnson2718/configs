# TODO I'd like an enum flag to dictate power saving vs performance mode and be
# able selectively switch between the two.

# TODO Also want to do actual power draw testing

# TODO also want to expose and set up luks disk encryption

{config, lib, modulesPath, pkgs, ...}:
let
  cfg = config.asus-gu603;
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  options = {
    asus-gu603.enable = lib.mkEnableOption "Enable config for asus-gu603";
  };

  config = lib.mkIf cfg.enable {
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

    swapDevices = [ ];

    boot = {
      kernelPackages = pkgs.linuxPackages_6_11;
      initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "vmd" "nvme" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
      initrd.kernelModules = [ ];
      kernelModules = [ "kvm-intel" ];
      extraModulePackages = [ ];
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };

    nvidiaPrime.enable = true;
  };
}
