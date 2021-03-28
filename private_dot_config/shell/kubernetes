[[ -f "${XDG_DATA_HOME}/fubectl.source" ]] && source "${XDG_DATA_HOME}/fubectl.source"

command -v kubectl &> /dev/null
if [[ $? -eq 0 ]]
then

    if [[ -z ${KUBECTL_COMPLETE} ]]
    then
        if [[ "${SHELL}" =~ .*zsh ]]
        then
            source <(kubectl completion zsh)
        fi
        if [[ "${SHELL}" =~ .*bash ]]
        then
            source <(kubectl completion bash)
        fi
        KUBECTL_COMPLETE=1
    fi

fi
