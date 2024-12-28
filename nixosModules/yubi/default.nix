{config, lib, ... }: 
let
  cfg = config.yubi;
in  
{
  options = {
    yubi.enable = lib.mkEnableOption "Enable Yubi Module";
    yubi.id = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkIf cfg.enable {
    security.pam.yubico = {
      enable = true;
      debug = true;
      mode = "challenge-response";
      id = [ cfg.id ];
      control = "sufficient";
    };

    services.pcscd.enable = true;
  };
}
