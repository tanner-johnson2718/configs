{ pkgs, config,lib, ... }:
let
  cfg = config.bash;
in
{
  options = {
    bash.enable = lib.mkEnableOption "Enable bash home-manager module";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      bash-completion
      xclip
      btop
      wget
      zip
      unzip
      tree
      socat
      nmap
      jq
      bintools
      usbutils
      pciutils
      util-linux
      lsof
      patchelf
      nix-derivation
      wmctrl
      aircrack-ng
      nettools
      lshw
      wireshark-cli
      dtc
      tio
      wirelesstools
      dracut
      ethtool
    ];

    home.file = { 
      "${config.home.homeDirectory}/complete_alias" = { source = ./complete_alias;};
      "${config.home.homeDirectory}/.bash_complete" = {
        text = ''
          . ~/complete_alias
          complete -F _complete_alias jctl
          complete -F _complete_alias sctl
        '';
      };
    };

    home.sessionVariables = {
      EDITOR = "nvim";
    };

    home.shellAliases = {
      l = "ls -CF --color=auto";
      e = "exit";
      la = "alias";
      ll = "ls -la --color=auto";
      lf = "declare -F"; 
      lF = "declare";
      lc = "complete";
      lv = "echo shell levl = ''$SHLVL";
      lu = "systemctl list-units";

      jctl = "journalctl";
      sctl = "systemctl";
    };
    
    programs.kitty = {
      enable = true;
      themeFile = "Darkside";
    };
    
    programs.bash = {
      enable = true;
      enableCompletion = true;

      initExtra = ''
        source ~/.bash_complete

	# Grep-closure
        function gcl {
	  if [ $# -ne 2 ]; then
	    echo "pass ./result pattern"
	    return 1
	  fi
          nix path-info -r $1 | grep $2
        }
        export gcl

	# Grep-kill
	function gkill {
	  if [ $# -ne 1 ]; then
	    echo "pass pattern"
	    return 1
	  fi
	  kill -9 $(ps -aux | grep $1 | awk '{print $2}')
	}
	export gkill
	
	# Grep-ps
	function gps {
	  if [ $# -ne 1 ]; then
	    echo "pass pattern"
	    return 1
	  fi
	  ps -aux | grep $1
	}
	export gps

      '';
    };
  };
}
