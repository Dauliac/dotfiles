let
  wallpaperPath = ../wallpaper.jpg;
in
{
  # Pin noctalia's wallpaper to the same shared image used by stylix
  # (theme.nix) and hyprpaper (desktop/wallpaper.nix). Runtime UI tweaks
  # can't persist here — declarative-lock.nix pins the state file to an
  # empty read-only /nix/store path — so config.toml is the sole source.
  flake.modules.homeManager.noctalia = {
    programs.noctalia.settings.wallpaper = {
      enabled = true;
      fill_mode = "crop";
      default.path = toString wallpaperPath;
      automation.enabled = false;
    };
  };
}
