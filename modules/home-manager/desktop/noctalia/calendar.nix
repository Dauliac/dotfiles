{
  # Wire an ICS calendar URL (stored encrypted in the root `secrets.yaml`
  # under the `calendar_url` key) into Noctalia's calendar display.
  #
  # Mechanism
  # ---------
  # Noctalia reads calendars via evolution-data-server's SourceRegistry
  # (Scripts/python/src/calendar/calendar-events.py in noctalia-shell).
  # Any `.source` keyfile under `~/.local/share/evolution/sources/` is
  # picked up by EDS and surfaces in both the stock clock-dropdown
  # calendar and any plugin that depends on CalendarService (e.g.
  # noctalia-plugins/weekly-calendar).
  #
  # We render that keyfile via sops-nix so the URL stays encrypted at
  # rest and only lands on disk at activation. The URL goes in both
  # `Resource=` and `SoupURI=` under `[Webdav Backend]`: different EDS
  # releases prefer one or the other, and unknown keys are ignored.
  #
  # First-time pickup: evolution-source-registry (DBus-activated) caches
  # sources on start. If events don't appear after the first `xi home
  # switch`, either log out/in or run `systemctl --user restart
  # evolution-source-registry.service` to force a reload.
  #
  # Opt-in because the key must be present in `secrets.yaml`; otherwise
  # sops-nix activation fails. Same guard pattern as [[anytype]].
  flake.modules.homeManager.noctalia =
    {
      config,
      lib,
      ...
    }:
    let
      sourcesDir = "${config.home.homeDirectory}/.local/share/evolution/sources";
      calendarEnabled = config.myNoctalia.calendar.enable or false;
    in
    {
      options.myNoctalia.calendar = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Register the ICS calendar (sops key `calendar_url`) with evolution-data-server so Noctalia can display it.";
        };
        displayName = lib.mkOption {
          type = lib.types.str;
          default = "Manomano";
          description = "Human-readable name shown in Noctalia's calendar surfaces.";
        };
        color = lib.mkOption {
          type = lib.types.str;
          default = "#ef2929";
          description = "Hex color EDS tags this calendar's events with.";
        };
        refreshMinutes = lib.mkOption {
          type = lib.types.int;
          default = 30;
          description = "How often EDS re-fetches the ICS from the remote URL.";
        };
      };

      config = lib.mkIf calendarEnabled {
        sops.secrets.calendar_url = {
          # Materialise under a user-owned directory so sops-nix chown
          # cleanly; EDS itself only reads the rendered template below.
          path = "${config.home.homeDirectory}/.config/noctalia-calendar/.secrets/url";
          mode = "0600";
        };

        sops.templates."evolution-sources/noctalia-calendar.source" = {
          path = "${sourcesDir}/noctalia-calendar.source";
          mode = "0600";
          content = ''
            [Data Source]
            DisplayName=${config.myNoctalia.calendar.displayName}
            Enabled=true
            Parent=webcal-stub

            [Calendar]
            BackendName=webcal
            Color=${config.myNoctalia.calendar.color}
            Selected=true

            [Offline]
            StaySynchronized=true

            [Refresh]
            Enabled=true
            IntervalMinutes=${toString config.myNoctalia.calendar.refreshMinutes}

            [Security]
            Method=tls

            [Webdav Backend]
            AvoidIfmatch=false
            CalendarAutoSchedule=false
            DisplayName=${config.myNoctalia.calendar.displayName}
            EmailAddress=
            Resource=${config.sops.placeholder.calendar_url}
            SoupURI=${config.sops.placeholder.calendar_url}
          '';
        };
      };
    };
}
