# vi: set ft=bash:
# exa
# https://the.exa.website

command -v exa &> /dev/null
if [[ $? -eq 0 ]]
then
    alias ls="exa"
    alias tree="exa --tree"
fi
