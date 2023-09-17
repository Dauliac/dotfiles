#!/usr/bin/env bash

work() {
  cd "$(ghq root)/$(ghq list | fzf)" || return
}
