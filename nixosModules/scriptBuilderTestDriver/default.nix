{pkgs, inputs, lib, config, ...}:
let
  cfg = config.scriptBuilderTestDriver;
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
    scriptBuilderTestDriver.enable = lib.mkEnableOption "Enable module";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = 
      (sb.build {
	name = "sbTest1";
	description = "Basic script builder test";
	inherit args pkgs;
	text = ''
	  echo hello
	'';
      })
      ++(sb.build {
	name = "sbTest2";
	description = "Lets test the proc watcher";
	inherit args pkgs;
	text = ''
	  
	'';
      });
  };
}
