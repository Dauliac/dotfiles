export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE="$XDG_DATA_HOME"/history

HISTTIMEFORMAT="%d/%m/%y %T "
HISTCONTROL=ignorespace:erasedups:ignoreboth:ignoredups
PROMPT_COMMAND="${PROMPT_COMMAND}${PROMPT_COMMAND:+;}history -a; history -n"


IGNORE='ls:ps:history:exit'

if [ $SHELL = "/bin/bash" ]; then
    shopt -s histappend
    HISTIGNORE="$IGNORE"
fi

if [ $SHELL = "/bin/zsh" ]; then
    HISTORY_IGNORE="$IGNORE"
fi
