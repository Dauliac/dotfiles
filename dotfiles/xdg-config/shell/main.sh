#!/usr/bin/env bash

SOURCES_DIR="$(dirname "$0")"
export SOURCES_DIR

setup_defaults_programs() {
	export TERM_BIN="alacritty"
	export BROWSER="brave"
	export WORKSPACE="$HOME/Workspace"
	export TEMPLATES="$HOME/Templates"
	export PAGER="less"
	export EDITOR="nvim"
}

setup_bin_paths() {
	PATH="$HOME/.node_modules/bin:$PATH"
	# Node local bin
	PATH="$HOME/.local/bin:$PATH"
	export npm_config_prefix=~/.node_modules
	# Go local bin
	export GOPATH="$WORKSPACE/go"
	PATH="$GOPATH/bin:$PATH"
	# Rust local bin
	PATH="$CARGO_HOME/bin:$PATH"
}

setup_defaults_programs
setup_bin_paths

# shellcheck source=./dotfiles/xdg-config/shell/aliases.sh
source "$SOURCES_DIR"/aliases.sh
# shellcheck source=./dotfiles/xdg-config/shell/bat.sh
source "$SOURCES_DIR"/bat.sh
# shellcheck source=./dotfiles/xdg-config/shell/direnv.sh
source "$SOURCES_DIR"/direnv.sh
# shellcheck source=./dotfiles/xdg-config/shell/docker.sh
source "$SOURCES_DIR"/docker.sh
# shellcheck source=./dotfiles/xdg-config/shell/eza.sh
source "$SOURCES_DIR"/eza.sh
# shellcheck source=./dotfiles/xdg-config/shell/ghq.sh
source "$SOURCES_DIR"/ghq.sh
# shellcheck source=./dotfiles/xdg-config/shell/history.sh
source "$SOURCES_DIR"/history.sh
# shellcheck source=./dotfiles/xdg-config/shell/kubernetes.sh
source "$SOURCES_DIR"/kubernetes.sh
# shellcheck source=./dotfiles/xdg-config/shell/less.sh
source "$SOURCES_DIR"/less.sh
# shellcheck source=./dotfiles/xdg-config/shell/nvim.sh
source "$SOURCES_DIR"/nvim.sh
# shellcheck source=./dotfiles/xdg-config/shell/starship.sh
source "$SOURCES_DIR"/starship.sh
# shellcheck source=./dotfiles/xdg-config/shell/tools.sh
source "$SOURCES_DIR"/tools.sh
# shellcheck source=./dotfiles/xdg-config/shell/vagrant.sh
source "$SOURCES_DIR"/vagrant.sh
