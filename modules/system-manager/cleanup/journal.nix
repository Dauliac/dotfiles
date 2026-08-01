{
  flake.modules.systemManager.cleanup-journal = { pkgs, ... }: {
    systemd.services.cleanup-journal = {
      enable = true;
      description = "Systemd journal log cleanup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "cleanup-journal" ''
          set -eu
          export PATH="${pkgs.coreutils}/bin:${pkgs.systemd}/bin:$PATH"

          USAGE=$(df / | ${pkgs.gawk}/bin/awk 'NR==2 {gsub(/%/,""); print $5}')
          echo "Disk usage: $USAGE%"

          if [ "$USAGE" -ge 90 ]; then
            echo "CRITICAL: vacuuming journal to 3 days"
            journalctl --vacuum-time=3d
          elif [ "$USAGE" -ge 80 ]; then
            echo "WARNING: vacuuming journal to 7 days"
            journalctl --vacuum-time=7d
          else
            echo "OK: no journal cleanup needed"
          fi
        '';
      };
    };

    systemd.timers.cleanup-journal = {
      enable = true;
      description = "Journal log cleanup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "15min";
        Persistent = true;
      };
    };
  };
}
