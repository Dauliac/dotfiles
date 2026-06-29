{
  flake.modules.systemManager.cleanup-tmp =
    { pkgs, ... }:
    {
      systemd.services.cleanup-tmp = {
        enable = true;
        description = "Temporary files and user cache cleanup";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "cleanup-tmp" ''
            set -eu
            export PATH="${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH"

            USAGE=$(df / | ${pkgs.gawk}/bin/awk 'NR==2 {gsub(/%/,""); print $5}')
            echo "Disk usage: $USAGE%"

            if [ "$USAGE" -ge 90 ]; then
              echo "CRITICAL: cleaning tmp >1d and user caches >7d"
              find /tmp -type f -atime +1 -delete 2>/dev/null || true
              find /home -maxdepth 3 -name ".cache" -type d -exec find {} -type f -atime +7 -delete \; 2>/dev/null || true
            elif [ "$USAGE" -ge 80 ]; then
              echo "WARNING: cleaning tmp >3d"
              find /tmp -type f -atime +3 -delete 2>/dev/null || true
            else
              echo "OK: no tmp cleanup needed"
            fi
          '';
        };
      };

      systemd.timers.cleanup-tmp = {
        enable = true;
        description = "Temporary files cleanup timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "15min";
          Persistent = true;
        };
      };
    };
}
