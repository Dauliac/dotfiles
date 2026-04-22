{
  flake.modules.homeManager.niri =
    {
      pkgs,
      ...
    }:
    let
      configDir = ./.;
      nixGL = pkgs.nixgl.nixGLIntel;

      niriWithGL = pkgs.writeShellScriptBin "niri" ''
        exec ${nixGL}/bin/nixGLIntel ${pkgs.niri}/bin/niri "$@"
      '';

      niriSession = pkgs.writeShellScriptBin "niri-session" ''
        if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
          . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
        fi

        export PATH="$HOME/.nix-profile/bin:$PATH"

        export XDG_SESSION_TYPE=wayland
        export XDG_SESSION_DESKTOP=niri
        export XDG_CURRENT_DESKTOP=niri
        export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

        export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}"

        export NIXOS_OZONE_WL=1

        export XCURSOR_THEME="''${XCURSOR_THEME:-default}"
        export XCURSOR_SIZE="''${XCURSOR_SIZE:-24}"

        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

        if ! ${pkgs.systemd}/bin/systemctl --user is-active --quiet dbus.socket; then
          ${pkgs.systemd}/bin/systemctl --user start dbus.socket
        fi

        ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
          PATH DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE \
          XDG_SESSION_DESKTOP XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS \
          NIXOS_OZONE_WL XCURSOR_THEME XCURSOR_SIZE

        ${pkgs.systemd}/bin/systemctl --user import-environment \
          PATH DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE \
          XDG_SESSION_DESKTOP XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS \
          NIXOS_OZONE_WL XCURSOR_THEME XCURSOR_SIZE

        ${pkgs.systemd}/bin/systemctl --user start graphical-session.target

        exec ${nixGL}/bin/nixGLIntel ${pkgs.niri}/bin/niri
      '';
    in
    {
      xdg.configFile."niri/config.kdl".source = configDir + "/config.kdl";
      xdg.configFile."swaylock/config".source = configDir + "/mocha.conf";

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

      home.packages = with pkgs; [
        niriWithGL
        niriSession

        swaylock-effects
        swayidle
        wlogout
        waypaper

        xdg-desktop-portal
        xdg-desktop-portal-gtk

        wl-clipboard
        cliphist

        grim
        slurp

        playerctl
        brightnessctl
        pamixer

        swaybg

        xwayland-satellite
      ];
    };
}
