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
      # Enable the module.
      # Default: false
      enable = true;

      # Automatically restart HyprPanel with systemd.
      # Useful when updating your config so that you
      # don't need to manually restart it.
      # Default: false
      systemd.enable = true;

      # Add '/nix/store/.../hyprpanel' to the
      # 'exec-once' in your Hyprland config.
      # Default: false
      hyprland.enable = true;

      # Fix the overwrite issue with HyprPanel.
      # See below for more information.
      # Default: false
      overwrite.enable = true;

      # Import a specific theme from './themes/*.json'.
      # Default: ""
      theme = "gruvbox_split";

      # Configure bar layouts for monitors.
      # See 'https://hyprpanel.com/configuration/panel.html'.
      # Default: null
      layout = {
        "bar.layouts" = {
          "0" = {
            left = [
              "dashboard"
              "workspaces"
            ];
            middle = [ "media" ];
            right = [
              "volume"
              "systray"
              "notifications"
            ];
          };
        };
      };

      # Configure and theme *most* of the options from the GUI.
      # See './nix/module.nix:103'.
      # Default: <same as gui>
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
          name = "CaskaydiaCove NF";
          size = "16px";
        };
      };
    };
    waybar = {
      enable = true;
      systemd.enable = true;
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
            "network"
            "bluetooth"
            "battery"
            # "blacklight"
            "pulseaudio"
            "custom/lock"
            "custom/power"
          ];
          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
          };
          clock = {
            format = "🕐 {:%H:%M  📆 %Y/%m/%d}";
            tooltip = false;
          };
          network = {
            format-wifi = "  {essid}";
          };
          pulseaudio = {
            tooltip = false;
            scroll-step = 5;
            format = "{icon}  {volume}%";
            format-muted = "{icon}  {volume}%";
            on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
            format-icons = {
              default = [
                ""
                ""
                ""
              ];
            };
          };
          "custom/lock" = {
            tooltip = false;
            "on-click" = "sh -c '(sleep 0.5s; swaylock --grace 0)' & disown";
            format = "";
          };
          "custom/power" = {
            tooltip = false;
            on-click = "wlogout &";
            format = "";
          };
        };
      };
      style = ''
        * {
          font-family: FantasqueSansMono Nerd Font;
          font-size: 17px;
          min-height: 0;
        }
        #waybar {
          background: transparent;
          color: @text;
          margin: 5px 5px;
        }

        #workspaces {
          border-radius: 1rem;
          margin: 5px;
          background-color: @surface0;
          margin-left: 1rem;
        }

        #workspaces button {
          color: @lavender;
          border-radius: 1rem;
          padding: 0.4rem;
        }

        #workspaces button.active {
          color: @sky;
          border-radius: 1rem;
        }

        #workspaces button:hover {
          color: @sapphire;
          border-radius: 1rem;
        }

        #tray,
        #backlight,
        #clock,
        #battery,
        #pulseaudio,
        #custom-lock,
        #bluetooth,
        #network,
        #custom-power {
          background-color: @surface0;
          margin: 5px 0;
          padding: 0 15px 0 15px;
        }

        #network {
          border-radius: 1rem 0 0 1rem;
        }

        #clock {
          color: @blue;
          border-radius: 1rem;
        }

        #battery {
          color: @green;
          border-radius: 0 1rem 1rem 0;
        }

        #battery.charging {
          color: @green;
        }

        #battery.warning:not(.charging) {
          color: @red;
        }

        #pulseaudio {
          color: @maroon;
          border-radius: 1rem;
          margin-left: 1rem;
        }

        #custom-lock {
            margin-left: 1rem;
            border-radius: 1rem 0px 0px 1rem;
            color: @lavender;
        }

        #custom-power {
            margin-right: 1rem;
            border-radius: 0px 1rem 1rem 0px;
            color: @red;
        }

        #tray {
          margin-right: 1rem;
          border-radius: 1rem;
        }
      '';
    };
  };
}
