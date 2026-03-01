{ lib, ... }:
{
  config.dotfiles.nixos.sharedModules = lib.mkAfter [
    (_: {
      catppuccin = {
        enable = true;
        flavor = "mocha";
      };
    })
  ];
}
