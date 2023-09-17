#!/usr/bin/env bash

setup_fubectl() {
  # shellcheck source=/dev/null
  [[ -f "${XDG_DATA_HOME}/fubectl.source" ]] && source "${XDG_DATA_HOME}/fubectl.source"
}

setup_kubectl() {
  if command -v kubectl &>/dev/null; then
    if [[ -z ${KUBECTL_COMPLETE} ]]; then
      # shellcheck source=/dev/null
      source <(kubectl completion "$SHELL_NAME")
      KUBECTL_COMPLETE=1
    fi
  fi
}

setup_fubectl
setup_kubectl
