#!/usr/bin/env bash

setup_eza() {

  if command -v exa &>/dev/null; then
    alias ls="eza"
    alias tree="eza --tree"
  fi
}

setup_eza
