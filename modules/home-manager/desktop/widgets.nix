_: {
  services.mako = {
    enable = true;
  };
  programs = {
    tofi = {
      enable = true;
      settings = {
        height = "20%";
        width = "35%";
        border-width = 4;
        corner-radius = 4;
        font = "Iosevka Nerd Font";
        font-size = 16;
      };
    };
    hyprpanel = {
      # enable = true;
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
            middle = [
              "media"
            ];
            right = [
              "volume"
              "network"
              "bluetooth"
              "systray"
              "clock"
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
