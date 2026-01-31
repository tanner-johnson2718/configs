# Commands that should be applied only for interactive shells.
[[ $- == *i* ]] || return

ROOT="/var/git/configs/bashrc.sh"

if [ -f "$ROOT" ]; then
  echo "Found config root at $ROOT"
  source $ROOT
else
  echo "Could not find $ROOT .. fix this please"
fi
