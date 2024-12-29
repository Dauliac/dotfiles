{ pkgs, ... }:
{
  services.mako = {
    enable = true;
  };
  programs = {
    rofi = {
      enable = true;
      package = pkgs.rofi-wayland-unwrapped;
    };
    wpaperd = {
      enable = true;
      settings = {
        default = {
          path = ./wallpaper.jpg;
        };
      };
    };
    hyprpanel = {
      # FIXME: enable this after resolution of this issue: https://github.com/Jas-SinghFSU/HyprPanel/issues/655
      enable = false;
      systemd.enable = true;
      hyprland.enable = true;
      overwrite.enable = true;
      theme = "catppuccin_mocha";
      layout = {
        "bar.layouts" = {
          "0" = {
            left = [
              "dashboard"
              "workspaces"
            ];
            middle = [ "media" ];
            right = [
              "battery"
              "volume"
              "systray"
              "notifications"
            ];
          };
        };
      };
      settings = {
        bar.launcher.autoDetectIcon = true;
        bar.workspaces.show_icons = true;
        menus.clock = {
          time = {
            military = true;
            hideSeconds = true;
          };
          weather.unit = "metric";
        };
        menus.dashboard.directories.enabled = false;
        menus.dashboard.stats.enable_gpu = true;
        theme.bar.transparent = true;
        theme.font = {
          name = "Iosevka Nerd Font";
          size = "16px";
        };
      };
    };
  };
}
