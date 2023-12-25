{ config
, pkgs
, ..
}:
{
  enable = true;
  enableCompletion = true;
  enableAutosuggestions = true;
  autocd = true;
  syntaxHighlighting.enable = true;
  profileExtra = ''
    export XDG_SECRET_HOME="''${XDG_CONFIG_HOME}/secrets"
    # Source all files into XDG_SECRET_HOME
    source <(cat ''${XDG_SECRET_HOME:?}/*)

    # NOTE: this enable CTRL+e to eddit current command line
    autoload edit-command-line
    zle -N edit-command-line
    bindkey -M vicmd e edit-command-line
  '';
  history = (import ./history.nix { inherit config pkgs; }).zsh;
  prezto = {
    enable = true;
    autosuggestions.color = "fg=blue";
    editor.keymap = "vi";
    ssh.identities = [ "id_rsa" "id_dsa" ];
    syntaxHighlighting = {
      highlighters = [ "main" "brackets" "pattern" "line" "cursor" "root" ];
      styles = {
        builtin = "bg=blue";
        command = "bg=blue";
        function = "bg=blue";
      };

      pattern = { "rm*-rf*" = "fg=white,bold,bg=red"; };
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
}
