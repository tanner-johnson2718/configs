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
    wirelesstools
    iw
    nil
    ccls
    fd
    ripgrep
  ];

  programs.kitty = {
    enable = true;
    themeFile = "Darkside";
    extraConfig = ''
      map ctrl+shift+n no_op
      map ctrl+shift+enter no_op
      map ctrl+shift+t no_op
      map ctrl+space+z no_op
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

    gs = "git status";
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

  #############################################################################
  # TMUX Settings
  #############################################################################

  home.shellAliases = {
    tc = "tmux copy-mode                                  # T COPY";
    tw = "tmux new-window                                 # T WINDOW";
    tp = "tmux split-window -h -c '#{pane_current_path}'  # T PANE";
    tj = "tmux last-pane                                  # T JUMP";
    ts = "tmux swap-pane -D                               # T SWAP";
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
      set -g prefix C-Space
      unbind-key C-b
      bind-key C-Space send-prefix
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

      setw -g mode-keys vi
      bind-key -T copy-mode-vi y send-keys -X copy-selection "xclip -selection clipboard -i"
      bind-key -T copy-mode-vi v send -X begin-selection
      bind-key -T copy-mode-vi C-v send -X rectangle-toggle
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-selection "xclip -selection clipboard -i"

      bind-key -T copy-mode-vi C-Up send-keys -X previous-paragraph
      bind-key -T copy-mode-vi C-Down send-keys -X next-paragraph
      bind-key -T copy-mode-vi C-Left send-keys -X previous-word
      bind-key -T copy-mode-vi C-Right send-keys -X next-word-end

      unbind-key C-Left
      unbind-key C-Right
      unbind-key C-Up
      unbind-key C-Down
      bind-key -T prefix Up select-pane -U
      bind-key -T prefix Down select-pane -D
      bind-key -T prefix Left select-pane -L
      bind-key -T prefix Right select-pane -R

      bind-key -T prefix / split-window -h -c '#{pane_current_path}'
      bind-key -T prefix - split-window -v -c '#{pane_current_path}'

      set -s command-alias[00] tj='last-pane'
      set -s command-alias[01] tp='split-window -h'
      set -s command-alias[02] tw='new-window'
      set -s command-alias[03] tc='copy-mode'
      set -s command-alias[04] tl='rename-window'
      set -s command-alias[05] ts='swap-pane -D'
      set -s command-alias[06] tsd='swap-pane -D'
      set -s command-alias[07] tsu='swap-pane -U'
      set -s command-alias[08] th='split-window -v'

      set -s command-alias[100] t0='select-window -t 0'
      set -s command-alias[101] t1='select-window -t 1'
      set -s command-alias[102] t2='select-window -t 2'
      set -s command-alias[103] t3='select-window -t 3'
      set -s command-alias[104] t4='select-window -t 4'
      set -s command-alias[105] t5='select-window -t 5'
      set -s command-alias[106] t6='select-window -t 6'
      set -s command-alias[107] t7='select-window -t 7'
      set -s command-alias[108] t8='select-window -t 8'
      set -s command-alias[109] t9='select-window -t 9'
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

      userEmail = email;
      userName  = user;
    };
}
