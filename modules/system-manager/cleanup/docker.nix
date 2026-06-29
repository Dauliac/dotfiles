{
  flake.modules.systemManager.cleanup-docker =
    { pkgs, ... }:
    {
      systemd.services.cleanup-docker = {
        enable = true;
        description = "Docker cleanup (images, build cache, volumes)";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "cleanup-docker" ''
            set -eu
            export PATH="${pkgs.docker_29}/bin:${pkgs.coreutils}/bin:$PATH"

            USAGE=$(df / | ${pkgs.gawk}/bin/awk 'NR==2 {gsub(/%/,""); print $5}')
            echo "Disk usage: $USAGE%"

            if [ "$USAGE" -ge 90 ]; then
              echo "CRITICAL: pruning all unused docker data and volumes"
              docker system prune -af --volumes
            elif [ "$USAGE" -ge 80 ]; then
              echo "WARNING: pruning dangling docker images and build cache"
              docker image prune -f
              docker builder prune -f
            else
              echo "OK: no docker cleanup needed"
            fi
          '';
        };
      };

      systemd.timers.cleanup-docker = {
        enable = true;
        description = "Docker cleanup timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "15min";
          Persistent = true;
        };
      };
    };
}
