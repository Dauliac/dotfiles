#!/usr/bin/env bash

# https://the.exa.website

set_bat_as_cat() {

  if command -v bat &>/dev/null; then
    alias cat="bat"
  else
    if command -v batcat &>/dev/null; then
      alias cat="batcat"
    fi
  fi

}
set_bat_as_cat
