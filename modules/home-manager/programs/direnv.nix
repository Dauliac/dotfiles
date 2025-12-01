{ inputs, ... }:
{
  # imports = [ inputs.direnv-instant.homeModules.direnv-instant ];
  # programs.direnv-instant.enable = true;
  programs.direnv = {
    enable = true;
    # nix-direnv.enable = true;
    # mise.enable = true;
    enableZshIntegration = true;
    silent = true;
  };
  home.sessionVariables = {
    # DIRENV_INSTANT_MUX_DELAY = "80";
    DIRENV_LOG_FORMAT = ""; # NOTE: disable direnv log
    DIRENV_WARN_TIMEOUT = "80s";
  };
}
