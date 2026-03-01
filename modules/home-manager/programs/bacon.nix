{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (_: {
      programs.bacon = {
        enable = true;
      };
    })
  ];
}
