_: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = {
      enable = true;
    };
    autocd = true;
    syntaxHighlighting.enable = true;
    profileExtra = ''
      export XDG_SECRET_HOME="''${XDG_CONFIG_HOME}/secrets"
      # NOTE: this enable CTRL+e to eddit current command line
      autoload edit-command-line
      zle -N edit-command-line
      bindkey -M vicmd e edit-command-line
    '';
    initContent = ''
      # Set the default shell to zsh
      # Source all files into XDG_SECRET_HOME
      if [[ -d ''${XDG_SECRET_HOME} ]]; then
        source <(cat ''${XDG_SECRET_HOME:?}/*)
      fi
      export SECRET_OPENAI_PATH="$XDG_RUNTIME_DIR/secrets/openai_key"
      if [[ -f $SECRET_OPENAI_PATH ]]; then
        export OPENAI_KEY=$(cat $SECRET_OPENAI_PATH)
        export OPENAI_API_KEY=$(cat $SECRET_OPENAI_PATH)
      fi
      if command -v mise &> /dev/null; then
        eval "$(mise activate zsh)"
      fi
    '';
    prezto = {
      enable = true;
      autosuggestions = {
        color = "fg=blue";
      };
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
}
