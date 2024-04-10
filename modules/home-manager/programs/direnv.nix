_: {
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
  home.sessionVariables = {
    DIRENV_LOG_FORMAT = ""; # NOTE: disable direnv log
    DIRENV_WARN_TIMEOUT = "80s";
  };
}
