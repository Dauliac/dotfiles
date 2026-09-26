{
  # Startup policy: nothing spawned by niri itself. Everything that needs to
  # come up with the session is a systemd user unit bound to niri.service /
  # graphical-session.target — that gives us restart handling, structured
  # journal logs, and clean shutdown ordering. `spawn-at-startup` is
  # intentionally empty.
  #
  # Wallpaper is owned by noctalia's own daemon (see
  # modules/home-manager/desktop/noctalia/wallpaper.nix); no swaybg/waypaper
  # service is needed.
  flake.modules.homeManager.niri = {
    programs.niri.settings.spawn-at-startup = [ ];
  };
}
