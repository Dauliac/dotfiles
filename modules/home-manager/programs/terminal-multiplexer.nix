{
  flake.modules.homeManager.terminal-multiplexer = {
    programs.zsh.initContent = ''
      if [[ -z "$TMUX" && "$TERM" != "linux" && -z "$INSIDE_EMACS" && -z "$VSCODE_INJECTION" ]]; then
        exec tmux new-session -A -s main
      fi
    '';
  };
}
