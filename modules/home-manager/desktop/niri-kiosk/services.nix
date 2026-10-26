{
  # Per-app systemd user units for the kiosk apps.
  #
  # Pattern matches the rest of the niri session: everything is a
  # systemd user unit bound to graphical-session.target, no
  # `spawn-at-startup`. That gives us Restart=always semantics and
  # journal logs, matching startup.nix's policy.
  flake.modules.homeManager.niri-kiosk =
    { config, lib, ... }:
    let
      kioskApps = config.myNiri.kiosk.apps;

      serviceFor = name: app: {
        Unit = {
          Description = "niri kiosk app: ${name}";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = app.command;
          # Always-on: if the app exits or crashes it comes back up.
          Restart = "always";
          RestartSec = 2;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      kioskServices = lib.mapAttrs' (
        name: app:
        lib.nameValuePair "niri-kiosk-${name}" (serviceFor name app)
      ) kioskApps;
    in
    {
      systemd.user.services = kioskServices;
    };
}
