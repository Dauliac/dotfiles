{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (_: {
      catppuccin = {
        enable = true;
        cursors.enable = true;
        flavor = "mocha";
        k9s.transparent = true;
        btop.enable = true;
        tmux.enable = true;
      };
    })
  ];
}
