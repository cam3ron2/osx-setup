# Powerline
export POWERLINE_BASH_CONTINUATION=1
export POWERLINE_BASH_SELECT=1

if [ -z "$PS1" ]; then
  return
fi

_update_ps1() {
  PS1=$(powerline-shell $?)
}

if [[ $TERM != linux && ! $PROMPT_COMMAND =~ _update_ps1 ]]; then
  PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi

powerline-daemon -q
# End Powerline