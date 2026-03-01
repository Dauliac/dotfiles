{ lib, ... }:
let
  wallpaperPath = ./wallpaper.jpg;
in
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (
      _:
      let
        path = toString wallpaperPath;
      in
      {
        services.hyprpaper = {
          enable = true;
          settings = {
            ipc = "on";
            splash = false;
            splash_offset = 2.0;
            preload = [
              path
            ];
            wallpaper = [
              ",${path}"
            ];
          };
        };
      }
    )
  ];
}
