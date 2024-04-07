{pkgs, ...}: {
  programs = {
    rofi = {
      enable = true;
      package = pkgs.rofi-wayland-unwrapped;
      theme = ./rofi/catppuccin.rasi;
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
          ];
          modules-center = [
            "clock"
          ];
          modules-right = [
            "network"
            "upower"
            "blacklight"
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
