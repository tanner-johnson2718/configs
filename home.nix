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

    jctl = "journalctl";
    sctl = "systemctl";

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

      if [ -z $TMUX ]; then
	tmux attach
      fi

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
    '';
  };

  #############################################################################
  # TMUX Settings
  #############################################################################

  home.shellAliases = {
    tv = "tmux copy-mode";
    tc = "tmux new-window";
    tp = "tmux split-window -h -c '#{pane_current_path}'";
    tsd = "tmux swap-pane -D                              # T SWAP DOWN";
    tsu = "tmux swap-pane -U                              # T SWAP UP";
    th = "tmux split-window -v -c '#{pane_current_path}'  # T HALF";
    t0 = "tmux select-window -t 0";
    t1 = "tmux select-window -t 1";
    t2 = "tmux select-window -t 2";
    t3 = "tmux select-window -t 3";
    t4 = "tmux select-window -t 4";
    t5 = "tmux select-window -t 5";
    t6 = "tmux select-window -t 6";
    t7 = "tmux select-window -t 7";
    t8 = "tmux select-window -t 8";
    t9 = "tmux select-window -t 9";
  };

  programs.tmux = {
    enable = true;
    newSession = true;
    baseIndex = 1;
    extraConfig = ''
      set -g prefix M-Space
      unbind-key C-b
      bind-key M-Space send-prefix
      bind-key    v copy-mode
      bind-key -r m previous-window
      bind-key -r n next-window
      bind -r k select-pane -U 
      bind -r j select-pane -D 
      bind -r h select-pane -L 
      bind -r l select-pane -R 		

      set-option -g status-right ""
      set -g status-bg "#5b6078"
      set -g status-fg "#f9e2af"
      set-window-option -g window-status-current-style bg="#939ab7"
      set -g mouse on
      set -g renumber-windows on
      set-option -g status-position top
      set -g base-index 1 
      setw -g pane-base-index 1
      set-option -g history-limit 50000
      set-option -g repeat-time 0

      setw -g mode-keys vi
      bind-key -T copy-mode-vi y send-keys -X copy-selection "xclip -selection clipboard -i"
      bind-key -T copy-mode-vi v send -X begin-selection
      bind-key -T copy-mode-vi C-v send -X rectangle-toggle
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-selection "xclip -selection clipboard -i"

      bind-key -T prefix a split-window -v -c '#{pane_current_path}'
      bind-key -T prefix f split-window -h -c '#{pane_current_path}'
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
      set number
      set nowrap
      set spell
      set ve=block

      nnoremap ff :Telescope find_files<CR>
      nnoremap fb :Telescope buffers<CR>
      nnoremap fn :bNext<CR>
      nnoremap fm :bprevious<CR>
      nnoremap fs :Telescope live_grep<CR>
      nnoremap fc :bd<CR>
      nnoremap fd :Gdiffsplit<CR>
      nnoremap mp :MarkdownPreview<CR>
      nnoremap <C-PageUp> :bprevious<CR>
      nnoremap <C-PageDown> :bNext<CR>

      vnoremap f :VBox<CR>
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
      vim-fugitive
      render-markdown-nvim
      markdown-preview-nvim
      venn-nvim
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
