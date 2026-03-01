{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (_: {
      services.pueue = {
        enable = true;
      };
    })
  ];
}
