_:
let
  path = "/home/dauliac/ghq/github.com/Dauliac/dotfiles/modules/home-manager/desktop/wallpaper.jpg";
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
