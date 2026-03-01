{ lib, ... }:
{
  config.dotfiles.nixos.sharedModules = lib.mkAfter [
    (_: {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };
    })
  ];
}
