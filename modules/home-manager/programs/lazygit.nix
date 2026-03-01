{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (_: {
      programs.lazygit = {
        enable = true;
        settings = { };
      };
    })
  ];
}
