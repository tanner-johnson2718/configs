{config, lib, ...}:
let
  cfg = config.gitea-server;
in
{
  options = {
    gitea-server.enable = lib.mkEnableOption "Enable the gitea server module";
  };

  config = lib.mkIf cfg.enable {

  };
}
