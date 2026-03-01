{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (_: {
      programs.kitty = {
        enable = true;
        shellIntegration.enableZshIntegration = true;
      };
    })
  ];
}
