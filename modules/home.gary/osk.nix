{
  # HM-scoped squeekboard user unit, bound to graphical-session.target the
  # same way polkit-gnome / xwayland-satellite are wired in
  # modules/home-manager/desktop/niri/session.nix. This path receives
  # WAYLAND_DISPLAY and DBUS_SESSION_BUS_ADDRESS once niri runs
  # `systemctl --user import-environment` at session start, so squeekboard
  # can register sm.puri.OSK0 and listen to text-input-v3 focus events.
  #
  # Auto-popup rules:
  #   - GTK3/4 and Qt5/6 toolkits trigger it on text-field focus.
  #   - Electron needs --enable-wayland-ime.
  #   - XWayland apps won't trigger (protocol limitation, not fixable here).
  flake.modules.homeManager.user-gary =
    { pkgs, ... }:
    {
      systemd.user.services.squeekboard = {
        Unit = {
          Description = "On-screen keyboard (auto-popup via text-input-v3)";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.squeekboard}/bin/squeekboard";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
