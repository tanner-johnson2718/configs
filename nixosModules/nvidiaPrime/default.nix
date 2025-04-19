# TODO Will the system even work if this isn't set?

# TODO Could expose power settings and full GPU disable

{config, lib, ...}:
let
  cfg = config.nvidiaPrime;
in
{
  options = {
    nvidiaPrime.enable = lib.mkEnableOption "Enable Nvidia Prime";
  };

  config = lib.mkIf cfg.enable {

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
  };
}
