export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
source ~/git-prompt.sh
export PROMPT_COLOR='34'
export PS1='\n\[\033[01;''${PROMPT_COLOR}m\]\W\[\033[01;32m\]$(__git_ps1 " (%s)") \[\033[00m\] '

source ~/.bash_complete


alias l="ls -CF --color=auto";
alias e="exit";
alias la="alias";
alias ll="ls -la --color=auto";
alias lv="echo shell levl = ''$SHLVL";
alias lu="systemctl list-units";
alias gs="git status";
alias gd="git diff";
alias gdc="git add ./* ; git commit -m \"..\" ; git push";

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
