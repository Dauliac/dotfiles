{
  pkgs,
  osConfig,
  lib,
  ...
}: {
  services.mako = {
    enable = true;
    catppuccin.enable = true;
  };
  programs = {
    rofi = {
      enable = true;
      package = pkgs.rofi-wayland-unwrapped;
      theme = ./rofi/catppuccin.rasi;
    };
    wpaperd = {
      enable = true;
      settings = {
        default = {
          path = ./wallpaper.jpg;
        };
      };
    };
    waybar = {
      enable = true;
      style = ./waybar-style.css;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          modules-left = [
            "hyprland/workspaces"
            "hyprland/window"
            "wlr/taskbar"
            "cpu"
            "memory"
            "systemd-failed-units"
          ];
          modules-center = [
            "clock"
          ];
          modules-right = [
            "cava"
            "network"
            # "bluetooth"
            "upower"
            "blacklight"
            "backlight/slider"
            "pulseaudio"
          ];
          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
          };
          clock = {
            format = "🕐 {:%H:%M  📆 %Y/%m/%d}";
          };
          network = {
            format-wifi = "  {essid}";
          };
          pulseaudio = {
            tooltip = false;
            scroll-step = 5;
            format = "{icon} {volume}%";
            format-muted = "{icon} {volume}%";
            format-icons = {
              default = ["" "" ""];
            };
          };
        };
      };
    };
  };
}
