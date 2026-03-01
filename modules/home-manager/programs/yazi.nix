{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (_: {
      programs.yazi = {
        enable = true;
        settings = {
          manager = {
            show_hidden = true;
          };
        };
      };
    })
  ];
}
