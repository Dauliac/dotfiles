{
  # Replaces the hand-written `spawn-sh-at-startup "sleep 2 && …"` line
  # from the old niri-config.kdl. Vesktop / Chromium screenshare picks
  # up an empty source list unless xdg-desktop-portal-gnome sees a
  # Wayland env in its activation environment. The compositor publishes
  # WAYLAND_DISPLAY only after it starts, so we restart the portal
  # stack once graphical-session.target is up.
  flake.modules.homeManager.user-gary =
    { pkgs, ... }:
    let
      reload = pkgs.writeShellApplication {
        name = "niri-portal-reload";
        runtimeInputs = with pkgs; [
          systemd
          dbus
          coreutils
        ];
        text = ''
          set -eu
          # Stop the three portal units if they are running.
          systemctl --user stop \
            xdg-desktop-portal \
            xdg-desktop-portal-gtk \
            xdg-desktop-portal-gnome \
            2>/dev/null || true

          # Republish the Wayland env into the user bus so freshly
          # started portal daemons see it.
          dbus-update-activation-environment --systemd \
            WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP

          # Start the backends first, then the frontend. The frontend
          # does a portal name query on start-up so backends need to
          # be registered.
          systemctl --user start \
            xdg-desktop-portal-gtk \
            xdg-desktop-portal-gnome \
            xdg-desktop-portal
        '';
      };
    in
    {
      systemd.user.services.niri-portal-reload = {
        Unit = {
          Description = "Reload xdg-desktop-portal stack after niri start";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${reload}/bin/niri-portal-reload";
          RemainAfterExit = true;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
