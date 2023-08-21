# Aliases
alias grep="grep --color=auto"
alias ll="ls -al"
alias ls="ls --color=always --classify --group-directories-first --human-readable"
alias less="less -F"
# Folders
alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'

# Protections
alias mv='mv -i'
alias cp='cp -i'

# Trash
alias rm='trash-put '
alias restore='trash-restore'

alias clip="xclip -selection c"

# One char
alias g="git"
alias e="exit"
alias c="clear"
alias k="kubectl"

# Functions
alias sc="scratch"

# Containers
# alias kapitan="docker run -t --rm -u $(id -u) -v $(pwd):/src:delegated deepmind/kapitan"

# Correction
alias nano="nvim"
alias vim="nvim"

NEOVIM_PATH="$(ghq root)/$(ghq list | grep 'Dauliac/neovim')"
alias vim="nix run ${NEOVIM_PATH} --"
alias nvim="vim"
alias nano="vim"
