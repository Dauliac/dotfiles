let
  wallpaperPath = ./wallpaper.jpg;
in
{
  flake.modules.homeManager.wallpaper =
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
          preload = [ path ];
          wallpaper = [ ",${path}" ];
        };
      };
    };
}
