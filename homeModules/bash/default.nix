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
    ];

    home.file = { 
      "${config.home.homeDirectory}/complete_alias" = { source = ./complete_alias;};
      "${config.home.homeDirectory}/.bash_complete" = {
        text = ''
          . ~/complete_alias
          complete -F _complete_alias jctl
          complete -F _complete_alias sctl
          complete -F _complete_alias cc
	  complete -F _complete_alias nsq
        '';
      };
    };

    home.sessionVariables = {
      EDITOR = "nvim";
    };

    home.shellAliases = {
      l = "ls -CF --color=auto";
      g = "grep --color=auto";
      e = "exit";
      c = "clear";

      la = "alias";
      ll = "ls -la --color=auto";
      lf = "declare -F"; 
      lF = "declare";
      lc = "complete";
      lv = "echo shell levl = ''$SHLVL";
      lw = "echo 'Desktops)' ; wmctrl -d ; echo '' ; echo 'Windows)' ; wmctrl -lG";
      lu = "systemctl list-units";

      nsq = "nix-store --query";

      jctl = "journalctl";
      sctl = "systemctl";

      gsettings = "GSK_RENDERER=gl gnome-control-center";
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

	# Closure
        function cl {
	  if [ $# -ne 1 ]; then
	    echo "pass ./result"
	    return 1
	  fi
          nix path-info -r $1
        }
        export cl

	# Grep-closure
        function gcl {
	  if [ $# -ne 2 ]; then
	    echo "pass ./result pattern"
	    return 1
	  fi
          nix path-info -r $1 | grep $2
        }
        export gcl

	# Firefox
        function ff {
	  if [ $# -ne 1 ]; then
	    echo "pass file"
	    return 1
	  fi
          firefox-esr $1
        }
	export ff

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

	# Dervier of nix store object
	function drv {
	  if [ $# -ne 1 ]; then
	    echo "pass /nix/store/obj"
	    return 1
	  fi
	  nix-store --query --deriver
	}
	export drv
      '';
    };
  };
}
