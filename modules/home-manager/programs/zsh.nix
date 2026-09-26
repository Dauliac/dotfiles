{
  flake.modules.homeManager.zsh = { config, ... }: {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      dotDir = "${config.xdg.configHome}/zsh";
      autosuggestion.enable = true;
      autocd = true;
      syntaxHighlighting.enable = true;
      profileExtra = ''
        export XDG_SECRET_HOME="''${XDG_CONFIG_HOME}/secrets"
        autoload edit-command-line
        zle -N edit-command-line
        bindkey -M vicmd e edit-command-line
      '';
      initContent = ''
        if [[ -d ''${XDG_SECRET_HOME} ]]; then
          source <(cat ''${XDG_SECRET_HOME:?}/*)
        fi
        export SECRET_OPENAI_PATH="$XDG_RUNTIME_DIR/secrets/openai_key"
        if [[ -f $SECRET_OPENAI_PATH ]]; then
          export OPENAI_KEY=$(cat $SECRET_OPENAI_PATH)
          export OPENAI_API_KEY=$(cat $SECRET_OPENAI_PATH)
        fi
        # Visual marker for shells launched inside an AI-owned herdr split.
        # The env vars are injected by herdr-run / herdr-tui at `pane split
        # --env` time, so this only fires in agent-spawned panes.
        if [[ -n "''${HERDR_AI_SPLIT:-}" ]]; then
          _herdr_ai_marker() {
            local role="''${HERDR_AI_ROLE:-ai}"
            local parent="''${HERDR_AI_PARENT_PANE:-?}"
            print -P "%F{red}%B[🤖 AI · $role ← $parent]%b%f"
          }
          precmd_functions=(_herdr_ai_marker $precmd_functions)
        fi
        if command -v mise &> /dev/null; then
          eval "$(mise activate zsh)"
        fi
      '';
      prezto = {
        enable = true;
        autosuggestions.color = "fg=blue";
        editor.keymap = "vi";
        ssh.identities = [
          "id_rsa"
          "id_dsa"
        ];
        syntaxHighlighting = {
          highlighters = [
            "main"
            "brackets"
            "pattern"
            "line"
            "cursor"
            "root"
          ];
          styles = {
            builtin = "bg=blue";
            command = "bg=blue";
            function = "bg=blue";
          };
          pattern = {
            "rm*-rf*" = "fg=white,bold,bg=red";
          };
        };
        pmodules = [
          "environment"
          "terminal"
          "editor"
          "history"
          "directory"
          "spectrum"
          "utility"
          "completion"
        ];
      };
    };
  };
}
