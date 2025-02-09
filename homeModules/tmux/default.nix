# TODO can I bring a pane from a diferent window into my current window?

{ config, lib, ... }:
let
  cfg = config.tmux;
in
{
  options = {
    tmux.enable = lib.mkEnableOption "Enable tmux module";
  };

  config = lib.mkIf cfg.enable {
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
	bind-key    z command-prompt
	bind-key    v copy-mode
	bind-key -r b previous-window
	bind-key -r n next-window

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

    programs.bash.initExtra = ''
      if [ -z $TMUX ]; then
	  tmux attach
      fi
    '';
  };
}
