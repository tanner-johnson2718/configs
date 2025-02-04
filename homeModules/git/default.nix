# Git is somewhat of a bad name for this module, also contains stuff like fd
# and ripgrep.

{config, lib, ...}:
let
  cfg = config.git;
in
{
  options = {
    git.enable = lib.mkEnableOption "Enable git module";
    git.email = lib.mkOption { type = lib.types.str; };
    git.userName = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      "${config.home.homeDirectory}/git-prompt.sh" = { source = ./git-prompt.sh;};
    };

    home.shellAliases = {
      gs = "git status";
    };

    programs.git = {
      enable = true;
      aliases = {
	s = "switch";
	sm = "switch master";
	a = "add";
	c = "commit";
	co = "checkout";
      };

      ignores = [
	"*.o"
	"*.so"
	".FCBak"
      ];

      lfs.enable = true;
      userEmail = cfg.email;
      userName =  cfg.userName;
    };

    programs.fd = {
      enable = true;
    };

    programs.ripgrep = {
      enable = true;
    };

    programs.bash = {
      initExtra = ''
	export GIT_PS1_SHOWCOLORHINTS=true
	export GIT_PS1_SHOWDIRTYSTATE=true
	export GIT_PS1_SHOWUNTRACKEDFILES=true
	source ~/git-prompt.sh
	export PROMPT_COLOR='34'
	export PS1='\n\[\033[01;''${PROMPT_COLOR}m\]\W\[\033[01;32m\]$(__git_ps1 " (%s)") \[\033[00m\] '
      '';
    };
  };
}
