HISTFILESIZE=100000
HISTSIZE=10000

shopt -s histappend
shopt -s extglob
shopt -s globstar
shopt -s checkjobs

source /var/git/configs/git-prompt.sh
export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export PROMPT_COLOR='34'
export PS1='\n\[\033[01;''${PROMPT_COLOR}m\]\W\[\033[01;32m\]$(__git_ps1 " (%s)") \[\033[00m\] '

dconf write /org/gnome/desktop/input-sources/xkb-options "['caps:ctrl_modifier']"

alias l="ls -CF --color=auto";
alias e="exit";
alias la="alias";
alias ll="ls -la --color=auto";
alias lv="echo shell levl = ''$SHLVL";
alias lu="systemctl list-units";
alias gs="git status";
alias gd="git diff";
alias gdc="git add ./* ; git commit -m \"..\" ; git push";
alias nvim="/nix/store/0iajsr2dpkv0h14h7w6mp404blald2g5-neovim-0.11.5/bin/nvim"
