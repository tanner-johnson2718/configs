# home.nix - configs my personal terminal and dev environment

# TODO Code fence macro
# TODO 80 char limit

{config, lib, pkgs, ...}:
let
  email = "tanner.johnson2718@gmail.com";
  user  = "tanner-johnson2718"; 
in
{
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
    iw
    nil
    ccls
    fd
    ripgrep
    httpie

    gnomeExtensions.freon

    google-chrome
    yubioath-flutter
    qbittorrent
    vlc
    atlauncher
    drawio
    libreoffice
    freecad
  ];

  programs.kitty = {
    enable = true;
    themeFile = "Darkside";
    extraConfig = ''
      map ctrl+shift+n no_op
      map ctrl+shift+enter no_op
      map ctrl+shift+t no_op
    '';
  };

  #############################################################################
  # Alias's, home files, and bash init
  #############################################################################
  
  home.file = { 
    "${config.home.homeDirectory}/complete_alias" = { source = ./complete_alias;};
    "${config.home.homeDirectory}/.bash_complete" = {
      text = ''
	. ~/complete_alias
	complete -F _complete_alias jctl
	complete -F _complete_alias sctl
      '';
    };
    "${config.home.homeDirectory}/git-prompt.sh" = { source = ./git-prompt.sh;};
    "${config.home.homeDirectory}/.background-image" = { source = ./.background-image; };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.shellAliases = {
    l = "ls -CF --color=auto";
    e = "exit";
    la = "alias";
    ll = "ls -la --color=auto";
    lv = "echo shell levl = ''$SHLVL";
    lu = "systemctl list-units";

    gs = "git status";
    gd = "git diff";
  };
    
  programs.bash = {
    enable = true;
    enableCompletion = true;

    initExtra = ''
      export GIT_PS1_SHOWCOLORHINTS=true
      export GIT_PS1_SHOWDIRTYSTATE=true
      export GIT_PS1_SHOWUNTRACKEDFILES=true
      source ~/git-prompt.sh
      export PROMPT_COLOR='34'
      export PS1='\n\[\033[01;''${PROMPT_COLOR}m\]\W\[\033[01;32m\]$(__git_ps1 " (%s)") \[\033[00m\] '
      
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
				kill -9 $(ps -aux | grep -i $1 | awk '{print $2}')
      }
      export gkill
    '';
  };

  #############################################################################
  # NVIM Settings
  ############################################################################# 
  
  programs.neovim = {
    enable       = true;
    viAlias      = true;
    vimAlias	 = true;
    vimdiffAlias = true;

    coc.enable = true;
    coc.settings = {
      languageserver = {
	nix = {
	  command = "nil";
	  filetypes = [ "nix" ];
	  rootPatterns = [ "flake.nix" ];
	};
	ccls =  {
	  command = "ccls";
	  filetypes = ["c"  "cc"  "cpp"  "c++"  "objc"  "objcpp"];
	  rootPatterns = [".ccls"  "compile_commands.json" ".git/" ".hg/"];
	};
      };
    };

    extraConfig = ''
      set autoindent
      set shiftwidth=2
      set softtabstop=2
      set tabstop=2
      set number
      set nowrap
      set spell
      set ve=block
		  set nu rnu

			nnoremap e $	

      nnoremap ff :Telescope find_files<CR>
      nnoremap fb :Telescope buffers<CR>
      nnoremap fn :bNext<CR>
      nnoremap fm :bprevious<CR>
      nnoremap fs :Telescope live_grep<CR>
      nnoremap fc :bd<CR>

      inoremap <C-s> <Esc>:w<CR>
			nnoremap <C-s> <Esc>:w<CR>

			nnoremap gb :Telescope git_branches<CR>
			nnoremap gl :Telescope git_commits<CR>
			nnoremap gs :Telescope git_status<CR>

			:tnoremap <Esc> <C-\><C-n>
			:tnoremap <C-s> <C-\><C-n>
    '';

    extraLuaConfig = ''
      local c = require('vscode.colors').get_colors()
      require('vscode').setup({
	  -- Alternatively set style in setup
	  -- style = 'light'

	  -- Enable transparent background 
	  transparent = true,

	  -- Enable italic comment
	  italic_comments = true,

	  -- Underline `@markup.link.*` variants
	  underline_links = true,

	  -- Disable nvim-tree background color
	  disable_nvimtree_bg = true,

	  -- Override colors (see ./lua/vscode/colors.lua)
	  color_overrides = {
	      vscLineNumber = '#FFFFFF',
	  },

	  -- Override highlight groups (see ./lua/vscode/theme.lua)
	  group_overrides = {
	      -- this supports the same val table as vim.api.nvim_set_hl
	      -- use colors from this colorscheme by requiring vscode.colors!
	  }
	})
	-- require('vscode').load()

	-- load the theme without affecting devicon colors.
	vim.cmd.colorscheme "vscode"
	vim.opt.clipboard = "unnamedplus"

	require'nvim-treesitter.configs'.setup {
	  highlight = {
	    enable = true,
	  }
	}
    '';

    plugins = with pkgs.vimPlugins; [
      vscode-nvim
      telescope-nvim
      git-blame-nvim
      render-markdown-nvim
      markdown-preview-nvim
      nvim-treesitter.withAllGrammars
    ];
  };

  #############################################################################
  # Git Settings
  ############################################################################# 

  programs.git = {
      enable = true;
      aliases = {
				sm = "switch master";
				co = "checkout";
      };

      ignores = [
				"*.o"
				"*.so"
				".FCBak"
				".a"
				".lib"
      ];

      userEmail = lib.mkDefault email;
      userName  = lib.mkDefault user;
    };

    #############################################################################
    # Dconf
    ############################################################################# 

    dconf.settings = {
      "org/gnome/desktop/background" = {
				picture-uri = "file:///${config.home.homeDirectory}/.background-image";
				picture-uri-dark = "file:///${config.home.homeDirectory}/.background-image";
				color-shading-type = "solid";
				picture-options = "zoom";
				primary-color = "#000000000000";
				secondary-color = "#000000000000";
      };
      "org/gnome/desktop/screensaver" = {
	picture-uri = "file:///${config.home.homeDirectory}/.background-image";
	picture-uri-dark = "file:///${config.home.homeDirectory}/.background-image";
	color-shading-type = "solid";
	picture-options = "zoom";
	primary-color = "#000000000000";
	secondary-color = "#000000000000";
      };
      "org/gnome/desktop/interface" = { 
	color-scheme = "prefer-dark";
	show-battery-percentage = true;
      };
      "org/gtk/gtk4/settings/file-chooser" = {
	show-hidden = true;
      };
      "org/gnome/desktop/wm/keybindings" = {
	activate-window-menu = ["<Alt>slash"];
      };
      "org/gnome/shell" = {
	favorite-apps = [
	  "kitty.desktop"
	  "google-chrome.desktop" 
	  "drawio.desktop" 
	  "org.gnome.Nautilus.desktop"
	  "com.yubico.authenticator.desktop" 
	  "steam.desktop" 
	  "atlauncher.desktop"
	];
	disable-user-extensions = false;
	enabled-extensions = [
	  "freon@UshakovVasilii_Github.yahoo.com"
	];
      };
    };
}
