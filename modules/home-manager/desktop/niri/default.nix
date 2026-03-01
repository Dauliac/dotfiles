{ lib, ... }:
let
  configDir = ./.;
in
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (
      { pkgs, ... }:
      let
        nixGL = pkgs.nixgl.nixGLIntel;

        # Wrapped niri binary with nixGL
        niriWithGL = pkgs.writeShellScriptBin "niri" ''
          exec ${nixGL}/bin/nixGLIntel ${pkgs.niri}/bin/niri "$@"
        '';

        # Session script that sets up environment and launches niri (matches NixOS setup)
        niriSession = pkgs.writeShellScriptBin "niri-session" ''
          # Source home-manager environment for PATH
          if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
            . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
          fi

          # Add home-manager profile to PATH
          export PATH="$HOME/.nix-profile/bin:$PATH"

          # XDG environment
          export XDG_SESSION_TYPE=wayland
          export XDG_SESSION_DESKTOP=niri
          export XDG_CURRENT_DESKTOP=niri
          export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

          # Wayland display
          export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}"

          # For Electron/Chromium apps on Wayland
          export NIXOS_OZONE_WL=1

          # Cursor settings
          export XCURSOR_THEME="''${XCURSOR_THEME:-default}"
          export XCURSOR_SIZE="''${XCURSOR_SIZE:-24}"

          # D-Bus session
          export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

          # Start D-Bus user session if not running
          if ! ${pkgs.systemd}/bin/systemctl --user is-active --quiet dbus.socket; then
            ${pkgs.systemd}/bin/systemctl --user start dbus.socket
          fi

          # KEY STEP: Import environment into D-Bus activation environment
          # This is what NixOS does - propagates env vars to D-Bus for portals
          ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
            PATH DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE \
            XDG_SESSION_DESKTOP XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS \
            NIXOS_OZONE_WL XCURSOR_THEME XCURSOR_SIZE

          # Also import into systemd user manager
          ${pkgs.systemd}/bin/systemctl --user import-environment \
            PATH DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE \
            XDG_SESSION_DESKTOP XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS \
            NIXOS_OZONE_WL XCURSOR_THEME XCURSOR_SIZE

          # Start graphical-session.target (required for portals and other services)
          ${pkgs.systemd}/bin/systemctl --user start graphical-session.target

          exec ${nixGL}/bin/nixGLIntel ${pkgs.niri}/bin/niri
        '';
      in
      {
        xdg.configFile."niri/config.kdl".source = configDir + "/config.kdl";
        xdg.configFile."swaylock/config".source = configDir + "/mocha.conf";

        # Portal configuration for Niri - use gtk for everything
        # gnome portal requires gnome-shell which isn't running
        xdg.configFile."xdg-desktop-portal/portals.conf".text = ''
          [preferred]
          default=gtk
          org.freedesktop.impl.portal.Screenshot=gtk
          org.freedesktop.impl.portal.ScreenCast=gtk
          org.freedesktop.impl.portal.Settings=gtk
          org.freedesktop.impl.portal.Background=gtk
          org.freedesktop.impl.portal.Inhibit=gtk
          org.freedesktop.impl.portal.FileChooser=gtk
          org.freedesktop.impl.portal.AppChooser=gtk
          org.freedesktop.impl.portal.Notification=gtk
          org.freedesktop.impl.portal.Wallpaper=gtk
          org.freedesktop.impl.portal.Secret=gnome-keyring
        '';

        # Noctalia shell (replaces waybar, mako, wofi, etc.)
        programs.noctalia-shell = {
          enable = true;
          systemd.enable = true; # Use systemd to properly start noctalia-shell with correct PATH
          settings = {
            bar = {
              position = "left";
              opacity = 0.9;
              widgetsLeft = [
                "Launcher"
                "Tray"
              ];
              widgetsCenter = [ "Workspace" ];
              widgetsRight = [
                "Clock"
                "NotificationHistory"
                "Battery"
                "Volume"
                "Brightness"
                "ControlCenter"
              ];
            };
            general = {
              animationSpeed = 1.0;
              shadow = true;
              font = "Iosevka Nerd Font";
              monoFont = "Iosevka Nerd Font Mono";
              clipboardHistory = true;
              volumeOverride = true;
            };
            plugins = {
              states = {
                "privacy-indicator" = true;
                "assistant-panel" = true;
                "catwalk" = true;
                "screen-recorder" = true;
                "screenshot" = true;
                "weekly-calendar" = true;
                "hyprland-steam-overlay" = true;
                "fancy-audiovisualizer" = true;
                "clipper" = true;
              };
            };
          };
          # Catppuccin Mocha color scheme
          colors = {
            mPrimary = "#cba6f7";
            mOnPrimary = "#1e1e2e";
            mPrimaryContainer = "#45475a";
            mOnPrimaryContainer = "#cdd6f4";
            mSecondary = "#89b4fa";
            mOnSecondary = "#1e1e2e";
            mSecondaryContainer = "#313244";
            mOnSecondaryContainer = "#cdd6f4";
            mTertiary = "#f5c2e7";
            mOnTertiary = "#1e1e2e";
            mTertiaryContainer = "#45475a";
            mOnTertiaryContainer = "#cdd6f4";
            mError = "#f38ba8";
            mOnError = "#1e1e2e";
            mErrorContainer = "#45475a";
            mOnErrorContainer = "#f38ba8";
            mSurface = "#1e1e2e";
            mOnSurface = "#cdd6f4";
            mOnSurfaceVariant = "#a6adc8";
            mSurfaceContainerLowest = "#11111b";
            mSurfaceContainerLow = "#181825";
            mSurfaceContainer = "#1e1e2e";
            mSurfaceContainerHigh = "#313244";
            mSurfaceContainerHighest = "#45475a";
            mSurfaceBright = "#585b70";
            mSurfaceDim = "#11111b";
            mInverseSurface = "#cdd6f4";
            mInverseOnSurface = "#1e1e2e";
            mInversePrimary = "#7c3aed";
            mOutline = "#6c7086";
            mOutlineVariant = "#45475a";
            mShadow = "#00000066";
            mScrim = "#000000";

            mPrimaryHover = "#b4befe";
            mSecondaryHover = "#74c7ec";
            mTertiaryHover = "#f5c2e7";
            mErrorHover = "#eba0ac";
            mSurfaceHover = "#313244";
          };
        };

        # Niri-related packages
        home.packages = with pkgs; [
          # Compositor (wrapped with nixGL)
          niriWithGL
          niriSession

          # Launchers and utilities
          swaylock-effects
          swayidle
          wlogout
          waypaper

          # Screen sharing / portals
          xdg-desktop-portal
          xdg-desktop-portal-gtk

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

          # X11 app support
          xwayland-satellite
        ];
      }
    )
  ];
}
