{
  flake.modules.homeManager.direnv = {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      silent = true;
    };
    home.sessionVariables = {
      DIRENV_LOG_FORMAT = "";
      DIRENV_WARN_TIMEOUT = "80s";
    };
  };
}
