{ pkgs, ... }:
{
  dotfiles = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
  shellEnv = {
    DIRENV_LOG_FORMAT = ""; # NOTE: disable direnv log
    DIRENV_WARN_TIMEOUT = "80s";
  };
};
