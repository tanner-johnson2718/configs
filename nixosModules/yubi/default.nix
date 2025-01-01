# Yubi Key PAM OTP module.
#
# Note to get serial number run 'nix-shell -p yubico-pam -p yubikey-manager' followed
# by ykman list.
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
#
# TODO investigate a Yubi Key U2F module where only the first set of commands
# are required and the only config you need is:
#   security.pam.services = {
#     login.u2fAuth = true;
#     sudo.u2fAuth = true;
#   };

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
