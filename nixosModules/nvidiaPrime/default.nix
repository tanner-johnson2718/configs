# TODO Will the system even work if this isn't set?

{config, lib, ...}:
let
  cfg = config.nvidiaPrime;
in
{
  options = {
    nvidiaPrime.enable = lib.mkEnableOption "Enable Nvidia Prime";
  };

  config = lib.mkIf cfg.enable {
    powerManagement = {
      enable = true;
      cpuFreqGovernor = "performance";
      scsiLinkPolicy = "max_performance";
    };

    hardware = {
      cpu.intel.updateMicrocode = true;
      
      graphics.enable = true;

      nvidia = {
        package            = config.boot.kernelPackages.nvidiaPackages.stable;
        open               = false;
        modesetting.enable = true;
        nvidiaSettings     = true;

        powerManagement = {
          enable = true;
          finegrained = true;
        };

        prime = {
          offload.enable   = true;
          offload.enableOffloadCmd = true;
          intelBusId    = "PCI:0:2:0";
          nvidiaBusId   = "PCI:1:0:0";
        };
      };
    };
  };
}
