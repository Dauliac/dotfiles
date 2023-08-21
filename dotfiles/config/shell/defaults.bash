# Defaults program variables
export TERM_BIN="/usr/bin/alacritty"
export BROWSER="/usr/bin/brave"
export READER="/usr/bin/zathura"
export WORKSPACE="$HOME/Workspace"
export TEMPLATES="$HOME/Templates"
export PAGER="/usr/bin/less"

export SHELL_PATH="$0"
export SHELL_NAME=$(basename "$shell_path")
# TODO: change it to work with nix
export EDITOR=nvim
export WORK_DIR=$(ghq root)

# bin #################################
# Node exec
PATH="$HOME/.node_modules/bin:$PATH"
# Node local bin
PATH="$HOME/.local/bin:$PATH"
export npm_config_prefix=~/.node_modules
# Go local bin
export GOPATH="$WORKSPACE/go"
PATH="$GOPATH/bin:$PATH"
# Rust local bin
PATH="$CARGO_HOME/bin:$PATH"
