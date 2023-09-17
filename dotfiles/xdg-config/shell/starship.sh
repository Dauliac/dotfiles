#!/usr/bin/env bash

setup_starship() {
  if command -v starship &>/dev/null; then
    export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship/config.toml"
    eval "$(starship init "$SHELL_NAME")"
  fi
}

setup_starship
