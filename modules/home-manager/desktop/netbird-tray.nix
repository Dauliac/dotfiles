{
  # netbird-ui tray under niri.
  #
  # The binary itself is intentionally NOT installed via nix — it comes
  # from the apt-installed `netbird-ui` .deb on ML-PF603JJ8 (see
  # modules/system-manager.ML-PF603JJ8/netbird.nix). The .deb build links
  # against Debian's libayatana-appindicator + gtk3 and picks up the
  # system icon theme without needing a nixgl wrapper, matching the
  # noctalia-from-apt strategy in modules/home-manager/desktop/noctalia.
  #
  # NetBird upstream ships an XDG .desktop autostart file with the
  # `netbird-ui` package, but niri deliberately does not honor XDG
  # autostart — HM's systemd-user + wayland.systemd.target is the
  # canonical way to bring a tray daemon up under a graphical session
  # here. Same pattern as noctalia + polkit-gnome + cliphist in this
  # tree (see modules/home-manager/desktop/niri/session.nix).
  #
  # The tray binary talks to the system daemon over its unix socket
  # (default /var/run/netbird.sock). The system daemon is managed by
  # the Debian netbird package's own systemd unit, wanted by
  # multi-user.target — it's up long before the user session, so the
  # tray unit doesn't need an explicit ordering dependency on it.
  flake.modules.homeManager.netbird-tray =
    { config, ... }:
    {
      systemd.user.services.netbird-ui = {
        Unit = {
          Description = "NetBird tray (apt-installed binary)";
          Documentation = "https://docs.netbird.io/";
          PartOf = [ config.wayland.systemd.target ];
          After = [ config.wayland.systemd.target ];
        };
        Service = {
          Type = "simple";
          ExecStart = "/usr/bin/netbird-ui";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ config.wayland.systemd.target ];
      };
    };
}
