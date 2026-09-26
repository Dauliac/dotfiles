{ inputs, ... }:
{
  # `system.autoUpgrade` on system-manager — mirrors the nixpkgs option
  # surface (nixos/modules/tasks/auto-upgrade.nix) so the same declaration
  # translates to Debian's unattended-upgrades via ansnix.
  #
  # Upstream numtide/system-manager already ships nix/modules/auto-upgrade.nix
  # that owns `options.system.autoUpgrade.*` for its
  # `system-manager switch --flake` timer path (see modules/default.nix in
  # the pinned system-manager rev). We disable that upstream module below
  # so this local one owns the namespace — the two implementations are
  # orthogonal (upstream re-runs system-manager itself; we drive Debian's
  # unattended-upgrades via ansnix), and on Debian only the Debian path
  # is meaningful. Keeping the nixpkgs-shaped option surface preserves
  # cross-backend parity with the companion NixOS module.
  #
  # We declare a subset of nixpkgs's fields: only those that map cleanly
  # onto unattended-upgrades + apt-daily.timer semantics. Fields nixpkgs
  # exposes that make no sense on Debian (`flake`, `channel`, `operation`,
  # `flags`, `pkgs`) are deliberately omitted — attempting to set them
  # fails at eval time as an unknown option, which is louder than silent
  # drift.
  #
  # `backend` selects the implementation. Default `"ansnix"` runs the
  # Debian playbook; `"native"` is a no-op on system-manager but is
  # honored by the companion `flake.modules.nixos.auto-upgrade` module
  # (see modules/nixos/auto-upgrade.nix) which force-disables nixpkgs's
  # `nixos-upgrade.service` + `.timer` when backend = "ansnix" on a
  # NixOS host that also imports the ansnix role, so only one path runs.
  #
  # Notification surface: post-run hook writes
  # /run/auto-upgrade/latest.json and broadcasts notify-send to every
  # active Wayland/X11 session — noctalia's notification daemon picks it
  # up natively. A stable JSON status file lives at
  # /var/lib/auto-upgrade/latest.json for future bar widgets.
  flake.modules.systemManager.auto-upgrade =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.system.autoUpgrade;
    in
    {
      # Disable upstream's `system.autoUpgrade` implementation so this
      # module owns the option namespace on system-manager hosts.
      disabledModules = [ "${inputs.system-manager}/nix/modules/auto-upgrade.nix" ];

      options.system.autoUpgrade = {
        enable = lib.mkEnableOption "automatic security upgrades";

        backend = lib.mkOption {
          type = lib.types.enum [ "ansnix" "native" ];
          default = "ansnix";
          description = ''
            Which implementation applies the upgrades.

            - `ansnix` (default): Debian unattended-upgrades driven by the
              ansnix playbook. This module implements it.
            - `native`: no-op on system-manager. On a NixOS host that
              imports the companion `flake.modules.nixos.auto-upgrade`
              bridge, this leaves nixpkgs's `system.autoUpgrade`
              implementation intact.

            Setting `backend = "ansnix"` on a NixOS host (via the bridge)
            force-disables the nixpkgs `nixos-upgrade.service` and
            `nixos-upgrade.timer` so only the ansnix playbook runs.
          '';
        };

        dates = lib.mkOption {
          type = lib.types.str;
          default = "04:40";
          example = "Sun 03:00";
          description = ''
            systemd `OnCalendar` spec for the upgrade timer. Translated
            to a drop-in on `apt-daily-upgrade.timer`.
          '';
        };

        randomizedDelaySec = lib.mkOption {
          type = lib.types.str;
          default = "45min";
          description = ''
            systemd `RandomizedDelaySec` applied to the timer to avoid
            thundering herds across a fleet.
          '';
        };

        persistent = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether the timer catches up after a missed activation
            (laptop asleep at the scheduled hour).
          '';
        };

        allowReboot = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Whether unattended-upgrades may reboot the host after
            installing an update flagged as reboot-required. On laptops,
            leave this false and let the notification prompt for a
            manual reboot instead.
          '';
        };

        rebootWindow = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                lower = lib.mkOption {
                  type = lib.types.str;
                  description = "HH:MM lower bound.";
                };
                upper = lib.mkOption {
                  type = lib.types.str;
                  description = "HH:MM upper bound (advisory, see notes).";
                };
              };
            }
          );
          default = null;
          example = {
            lower = "01:00";
            upper = "05:00";
          };
          description = ''
            Time-of-day window during which `allowReboot` may act.

            NOTE on Debian: unattended-upgrades only honors a single
            reboot hour via `Automatic-Reboot-Time` (mapped from
            `rebootWindow.lower`). The `upper` bound is accepted for
            cross-backend parity with nixpkgs but silently ignored — the
            reboot fires at `lower` regardless.
          '';
        };
      };

      config = lib.mkIf (cfg.enable && cfg.backend == "ansnix") {
        ansnix.roles.unattended-upgrades = {
          priority = 105; # after apt-repo (60) / apt-packages (100), before pam-line (110)
          tasks = [
            {
              name = "auto-upgrade | install unattended-upgrades + apt-listchanges";
              "ansible.builtin.apt" = {
                name = [
                  "unattended-upgrades"
                  "apt-listchanges"
                ];
                state = "present";
                update_cache = true;
                cache_valid_time = 3600;
              };
            }

            {
              name = "auto-upgrade | enable apt-daily.timer";
              "ansible.builtin.systemd" = {
                name = "apt-daily.timer";
                enabled = true;
                state = "started";
                daemon_reload = true;
              };
            }
            {
              name = "auto-upgrade | enable apt-daily-upgrade.timer";
              "ansible.builtin.systemd" = {
                name = "apt-daily-upgrade.timer";
                enabled = true;
                state = "started";
                daemon_reload = true;
              };
            }

            {
              name = "auto-upgrade | ensure persistent status directory exists";
              "ansible.builtin.file" = {
                path = "/var/lib/auto-upgrade";
                state = "directory";
                owner = "root";
                group = "root";
                mode = "0755";
              };
            }
          ];
        };

        # unattended-upgrades policy: security origin only, config-driven
        # reboot behavior, mail off (we surface via D-Bus).
        environment.etc."apt/apt.conf.d/50unattended-upgrades".text = ''
          Unattended-Upgrade::Origins-Pattern {
            "origin=Debian,codename=$${distro_codename},label=Debian-Security";
            "origin=Debian,codename=$${distro_codename}-security,label=Debian-Security";
          };

          Unattended-Upgrade::Package-Blacklist { };

          Unattended-Upgrade::DevRelease "auto";
          Unattended-Upgrade::AutoFixInterruptedDpkg "true";
          Unattended-Upgrade::MinimalSteps "true";
          Unattended-Upgrade::InstallOnShutdown "false";
          Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
          Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
          Unattended-Upgrade::Remove-Unused-Dependencies "false";
          Unattended-Upgrade::Automatic-Reboot "${lib.boolToString cfg.allowReboot}";
          ${lib.optionalString (cfg.allowReboot && cfg.rebootWindow != null) ''
            Unattended-Upgrade::Automatic-Reboot-Time "${cfg.rebootWindow.lower}";
          ''}
          Unattended-Upgrade::SyslogEnable "true";
          Unattended-Upgrade::Verbose "false";

          // Mail is off — status is surfaced via /run/auto-upgrade/latest.json
          // and a notify-send broadcast (see apt-daily-upgrade drop-in below).
          Unattended-Upgrade::Mail "";
        '';

        environment.etc."apt/apt.conf.d/20auto-upgrades".text = ''
          APT::Periodic::Update-Package-Lists "1";
          APT::Periodic::Download-Upgradeable-Packages "1";
          APT::Periodic::Unattended-Upgrade "1";
          APT::Periodic::AutocleanInterval "7";
        '';

        # Timer schedule drop-in — reflects cfg.dates / cfg.randomizedDelaySec
        # / cfg.persistent. The leading empty `OnCalendar=` clears Debian's
        # default so ours is the only one active.
        environment.etc."systemd/system/apt-daily-upgrade.timer.d/50-schedule.conf".text = ''
          [Timer]
          OnCalendar=
          OnCalendar=${cfg.dates}
          RandomizedDelaySec=${cfg.randomizedDelaySec}
          Persistent=${lib.boolToString cfg.persistent}
        '';

        # Post-run hook: write status JSON + broadcast notification to every
        # active graphical session. Runs as root inside apt-daily-upgrade.service;
        # notify-send is invoked via `systemd-run --user --machine=<user>@` so it
        # lands on the correct DBUS_SESSION_BUS_ADDRESS without scraping /proc.
        environment.etc."systemd/system/apt-daily-upgrade.service.d/50-notify.conf".text = ''
          [Service]
          ExecStartPost=${pkgs.writeShellScript "auto-upgrade-notify" ''
            set -u
            export PATH="${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.systemd}/bin:${pkgs.libnotify}/bin:/usr/bin:/bin"

            STATE_DIR=/var/lib/auto-upgrade
            RUN_DIR=/run/auto-upgrade
            mkdir -p "$RUN_DIR" "$STATE_DIR"

            LOG=/var/log/unattended-upgrades/unattended-upgrades.log
            TS=$(date --iso-8601=seconds)
            UPGRADED=0
            HELD=0
            REBOOT=false

            if [ -f "$LOG" ]; then
              UPGRADED=$(grep -c '^.*Packages that will be upgraded:' "$LOG" 2>/dev/null || echo 0)
              HELD=$(grep -c '^.*Packages with upgradable origin but kept back' "$LOG" 2>/dev/null || echo 0)
            fi
            [ -f /var/run/reboot-required ] && REBOOT=true

            EXIT="''${EXIT_STATUS:-0}"

            STATUS_JSON=$(printf '{"timestamp":"%s","exit_code":%s,"upgraded":%s,"held":%s,"kernel_reboot":%s,"backend":"ansnix"}' \
              "$TS" "$EXIT" "$UPGRADED" "$HELD" "$REBOOT")
            printf '%s\n' "$STATUS_JSON" > "$RUN_DIR/latest.json"
            printf '%s\n' "$STATUS_JSON" > "$STATE_DIR/latest.json"

            if [ "$REBOOT" = "true" ]; then
              SUMMARY="Reboot required after security upgrade"
              URGENCY=critical
            elif [ "$UPGRADED" -gt 0 ]; then
              SUMMARY="Applied $UPGRADED security upgrade(s)"
              URGENCY=normal
            elif [ "$EXIT" != "0" ]; then
              SUMMARY="Automatic upgrade failed (exit $EXIT)"
              URGENCY=critical
            else
              exit 0
            fi

            loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}' | while read -r SID; do
              USER=$(loginctl show-session "$SID" -p Name --value 2>/dev/null || true)
              TYPE=$(loginctl show-session "$SID" -p Type --value 2>/dev/null || true)
              STATE=$(loginctl show-session "$SID" -p State --value 2>/dev/null || true)
              case "$TYPE" in wayland|x11) ;; *) continue ;; esac
              [ "$STATE" = "active" ] || continue
              [ -n "$USER" ] || continue
              systemd-run --quiet --pipe --machine="$USER@" --user \
                -- notify-send \
                  --app-name=auto-upgrade \
                  --urgency="$URGENCY" \
                  "$SUMMARY" \
                  "$HELD held back — see /var/log/unattended-upgrades/" \
                || true
            done
          ''}
        '';
      };
    };
}
