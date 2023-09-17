#!/usr/bin/env bash

setup_nvim() {
  NEOVIM_PATH="$(ghq root)/$(ghq list | grep 'Dauliac/neovim')"
  export NEOVIM_PATH
  alias vim='nix run ${NEOVIM_PATH} --'
  alias nvim="vim"
  alias nano="vim"
}

setup_nvim
