{
  flake.modules.systemManager.cleanup-nix = { pkgs, ... }: {
    systemd.services.cleanup-nix = {
      enable = true;
      description = "Nix store garbage collection";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "cleanup-nix" ''
          set -eu
          export PATH="${pkgs.nix}/bin:${pkgs.coreutils}/bin:$PATH"

          USAGE=$(df / | ${pkgs.gawk}/bin/awk 'NR==2 {gsub(/%/,""); print $5}')
          echo "Disk usage: $USAGE%"

          if [ "$USAGE" -ge 90 ]; then
            echo "CRITICAL: removing all old nix generations"
            nix-collect-garbage -d
          elif [ "$USAGE" -ge 80 ]; then
            echo "WARNING: removing nix generations older than 7d"
            nix-collect-garbage --delete-older-than 7d
          else
            echo "OK: no nix cleanup needed"
          fi
        '';
      };
    };

    systemd.timers.cleanup-nix = {
      enable = true;
      description = "Nix store garbage collection timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "15min";
        Persistent = true;
      };
    };
  };
}
