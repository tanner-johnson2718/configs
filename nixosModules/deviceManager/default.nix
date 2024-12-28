# TODO explicitly define device list schema

# TODO actually implement

# TODO save each devices ip to known machines ssh

{lib, config, inputs, pkgs, ...}:
let
  cfg = config.deviceManager;
  sb = inputs.self.helpers.scriptBuilder;
  args = [
    {
      name = "arg1";
      description = "This is arg1";
      opts = "echo '0 1 2'";
    }
    {
      name = "arg2";
      description = "This is arg2";
      opts = "echo 'a b c'";
    }
  ];
in
{
  options = {
    deviceManager.enable = lib.mkEnableOption "Enable Device Manager";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = 
      sb.build {
	name = "devMan";
	description = "This is a device manager script";
	inherit args pkgs;
	text = ''
	  echo hello
	'';
    };
  };

}
