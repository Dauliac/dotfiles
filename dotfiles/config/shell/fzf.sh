# fzf
# https://github.com/junegunn/fzf/wiki

key_binding='.'
completion='/usr/share/fzf/completion.'

_source_zsh_completion() {
    # bash
    if [[ "${SHELL}" =~ ".*bash.*" ]]; then
        key_binding="${1}.bash"
        completion="${2}.bash"
    elif [[ "${SHELL}" =~ ".*zsh.*" ]]; then
        key_binding="${1}.zsh"
        completion="${2}.zsh"
    else
        echo 1
    fi

    [ -f "$key_binding" ] && source $key_binding
    [ -f "$completion" ] && source $completion
}

_source_zsh_completion "/usr/share/fzf/key-bindings" "/usr/share/fzf/completion"
_source_zsh_completion "$HOME/.fzf/shell/key-bindings" "$HOME/.fzf/shell/completion"

# Setting fd as the default source for fzf
export FZF_DEFAULT_COMMAND='fd --type f --color=always'

export FZF_DEFAULT_OPTS='--height 15% --border --layout=reverse --ansi'

# To apply the command to CTRL-T as well
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Use fd (https://github.com/sharkdp/fd) instead of the default find
# command for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"# History
}

FZF_COMPLETION_TRIGGER="**"

# Work with fasd
# fasd & fzf change directory - jump using `fasd` if given argument, filter output of `fasd` using `fzf` else
unalias z 2> /dev/null
z() {
  [ $# -gt 0 ] && fasd_cd -d "$*" && return
  local dir
  dir="$(fasd -Rdl "$1" | fzf -1 -0 --no-sort +m)" && cd "${dir}" || return 1
}

# Use fd (https://github.com/sharkdp/fd) instead of the default find
# command for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

# zsh; needs setopt re_match_pcre. You can, of course, adapt it to your own shell easily.
tmuxkillf () {
    local sessions
    sessions="$(tmux ls|fzf --exit-0 --multi)"  || return $?
    local i
    for i in "${(f@)sessions}"
    do
        [[ $i =~ '([^:]*):.*' ]] && {
            echo "Killing $match[1]"
            tmux kill-session -t "$match[1]"
        }
    done
}

# tm - create new tmux session, or switch to existing one. Works from within tmux too. (@bag-man)
# `tm` will allow you to select your tmux session via fzf.
# `tm irc` will attach to the irc session (if it exists), else it will create it.
tm() {
  [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
  if [ $1 ]; then
    tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
  fi
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
}


# Docker
## Docker fzf completion
export DOCKER_FZF_PREFIX="--bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all"

_fzf_complete_docker_run_post() {
    awk '{print $1":"$2}'
}

_fzf_complete_docker_run () {
    _fzf_complete "$DOCKER_FZF_PREFIX -m --header-lines=1" "$@" < <(
        docker images
    )
}

_fzf_complete_docker_common_post() {
    awk -F"\t" '{print $1}'
}

_fzf_complete_docker_common () {
    _fzf_complete "$DOCKER_FZF_PREFIX --reverse -m" "$@" < <(
        docker images --format "{{.Repository}}:{{.Tag}}\t {{.ID}}"
    )
}

_fzf_complete_docker_container_post() {
    awk '{print $NF}'
}

_fzf_complete_docker_container () {
    _fzf_complete "$DOCKER_FZF_PREFIX -m --header-lines=1" "$@" < <(
        docker ps -a
    )
}


_fzf_complete_docker() {
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    if ! type _docker > /dev/null 2>&1; then
        _completion_loader "$@"
        complete -F _fzf_complete_docker -o default -o bashdefault docker
    fi

    local counter=1
    while [ $counter -lt $cword ]; do
        case "${words[$counter]}" in
            run)
                _fzf_complete_docker_run "$@"
                return
            ;;
            exec|rm)
                _fzf_complete_docker_container "$@"
                return
            ;;
            save|load|push|pull|tag|rmi)
                _fzf_complete_docker_common "$@"
                return
            ;;
        esac
        (( counter++ ))
    done
    _fzf_handle_dynamic_completion docker "$@"
}
