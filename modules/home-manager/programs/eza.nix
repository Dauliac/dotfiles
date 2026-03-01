{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (_: {
      programs.eza = {
        enable = true;
        git = true;
        icons = "auto";
      };
    })
  ];
}
