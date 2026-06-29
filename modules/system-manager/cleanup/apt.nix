{
  flake.modules.systemManager.cleanup-apt =
    { pkgs, ... }:
    {
      systemd.services.cleanup-apt = {
        enable = true;
        description = "APT cleanup (autoremove, clean cache)";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "cleanup-apt" ''
            set -eu
            export PATH="${pkgs.coreutils}/bin:/usr/bin:$PATH"

            USAGE=$(df / | ${pkgs.gawk}/bin/awk 'NR==2 {gsub(/%/,""); print $5}')
            echo "Disk usage: $USAGE%"

            if [ "$USAGE" -ge 80 ]; then
              echo "Cleaning APT orphans and cache"
              apt-get autoremove -y
              apt-get clean
            else
              echo "OK: no APT cleanup needed"
            fi
          '';
        };
      };

      systemd.timers.cleanup-apt = {
        enable = true;
        description = "APT cleanup timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "15min";
          Persistent = true;
        };
      };
    };
}
