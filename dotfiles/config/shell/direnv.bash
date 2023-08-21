export DIRENV_WARN_TIMEOUT=20s
export DIRENV_LOG_FORMAT=""

eval "$(direnv hook ${SHELL_NAME})"
