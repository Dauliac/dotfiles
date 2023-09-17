#!/usr/bin/env bash

set_color_aliases() {
  alias grep="grep --color=auto"
  alias ll="ls -al"
  alias ls="ls --color=always --classify --group-directories-first --human-readable"
  alias less="less -F"
}
set_trash_aliases() {
  alias rm='trash-put '
  alias restore='trash-restore'
}

set_protection_aliases() {
  alias mv='mv -i'
  alias cp='cp -i'
}

set_aliases() {
  set_color_aliases
  set_protection_aliases
  set_trash_aliases

  alias clip="xclip -selection c"
}
set_aliases
