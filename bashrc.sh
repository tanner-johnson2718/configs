# Make sure we defined _CONFIG_ROOT in .bashrc
if [[ ! -v _CONFIG_ROOT ]]; then
  echo "Please Define _CONFIG_ROOT in .bashrc as path to configs repo"
fi

# Commands that should be applied only for interactive shells.
[[ $- == *i* ]] || return

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
alias nvim="$_CONFIG_ROOT/.nvim/bin/nvim";

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

# Size of Nix Closure
function scl {
  if [ $# -ne 1 ]; then
    echo "pass /nix/store/<hash>"
    return 1
  fi
  nix-store -qR $1 | xargs nix-store -q --size | awk '{s+=$1} END {print s}' | numfmt --to=iec
}
export scl

# Build nvim at location of this file. Above alias points "nvim" here
echo "REBUILDING NEOVIM .... BY THE WAY"
figlet -f slant NVIM
nix-build $_CONFIG_ROOT/nvim.nix -o .nvim
