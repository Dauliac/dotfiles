#!/usr/bin/env bash

setup_direnv() {
  export DIRENV_WARN_TIMEOUT=30s
  export DIRENV_LOG_FORMAT=""

  eval "$(direnv hook "$SHELL_NAME")"
}

setup_direnv
