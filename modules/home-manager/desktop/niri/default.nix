{ pkgs, ... }:
let
  nixGL = pkgs.nixgl.nixGLIntel;

  # Wrapped niri binary with nixGL
  niriWithGL = pkgs.writeShellScriptBin "niri" ''
    exec ${nixGL}/bin/nixGLIntel ${pkgs.niri}/bin/niri "$@"
  '';

  # Session script that sets up environment and launches niri
  niriSession = pkgs.writeShellScriptBin "niri-session" ''
    # Source home-manager environment for PATH
    if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    fi

    # Add home-manager profile to PATH
    export PATH="$HOME/.nix-profile/bin:$PATH"

    export XDG_SESSION_TYPE=wayland
    export XDG_SESSION_DESKTOP=niri
    export XDG_CURRENT_DESKTOP=niri

    # For screen sharing
    export XDG_CURRENT_DESKTOP=niri:GNOME

    exec ${nixGL}/bin/nixGLIntel ${pkgs.niri}/bin/niri
  '';
in
{
  xdg.configFile."niri/config.kdl".source = ./config.kdl;
  xdg.configFile."swaylock/config".source = ./mocha.conf;
  # home.file.".local/bin/nws.sh".source = ./nws.sh;

  # Niri-related packages
  home.packages = with pkgs; [
    # Compositor (wrapped with nixGL)
    niriWithGL
    niriSession

    # Bar
    waybar

    # Launchers and utilities
    wofi
    swaylock-effects
    swayidle
    wlogout
    waypaper

    # Screen sharing / portals
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk

    # Notifications
    mako

    # Clipboard
    wl-clipboard
    cliphist

    # Screenshot
    grim
    slurp

    # Media/audio control
    playerctl
    brightnessctl
    pamixer

    # Wallpaper
    swaybg
  ];

  # Waybar configuration for Niri
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;

        modules-left = [
          "niri/workspaces"
          "niri/window"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "temperature"
          "tray"
        ];

        "niri/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "brow" = "";
            "term" = "";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "obs" = "";
            "oss" = "";
          };
          on-click = "activate";
        };

        "niri/window" = {
          format = "{}";
          max-length = 50;
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        cpu = {
          format = " {usage}%";
          tooltip = true;
        };

        memory = {
          format = " {}%";
        };

        temperature = {
          critical-threshold = 80;
          format = " {temperatureC}°C";
        };

        network = {
          format-wifi = " {signalStrength}%";
          format-ethernet = " {ipaddr}";
          format-disconnected = "⚠ Disconnected";
          tooltip-format = "{ifname}: {ipaddr}";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = " muted";
          format-icons = {
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = "pavucontrol";
        };

        tray = {
          spacing = 10;
        };
      };
    };

    style = ''
      * {
        font-family: "Iosevka Nerd Font", monospace;
        font-size: 14px;
      }

      window#waybar {
        background-color: rgba(30, 30, 46, 0.9);
        color: #cdd6f4;
        border-bottom: 2px solid #45475a;
      }

      #workspaces button {
        padding: 0 8px;
        color: #6c7086;
        background: transparent;
        border-radius: 4px;
      }

      #workspaces button.active {
        color: #cba6f7;
        background: rgba(203, 166, 247, 0.2);
      }

      #workspaces button:hover {
        background: rgba(108, 112, 134, 0.3);
      }

      #clock,
      #cpu,
      #memory,
      #temperature,
      #network,
      #pulseaudio,
      #tray {
        padding: 0 10px;
        margin: 4px 2px;
        background-color: rgba(69, 71, 90, 0.5);
        border-radius: 4px;
      }

      #clock {
        color: #89b4fa;
      }

      #cpu {
        color: #f38ba8;
      }

      #memory {
        color: #fab387;
      }

      #temperature {
        color: #f9e2af;
      }

      #temperature.critical {
        color: #f38ba8;
      }

      #network {
        color: #a6e3a1;
      }

      #pulseaudio {
        color: #cba6f7;
      }

      #tray {
        color: #cdd6f4;
      }
    '';
  };

  # Note: mako package is included above for Niri, but service is not enabled
  # to avoid conflict with hyprpanel (used with Hyprland)
  # To use mako with Niri, start it manually: mako &
}
