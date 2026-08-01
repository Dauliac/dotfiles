{
  flake.modules.systemManager.cleanup-flatpak = { pkgs, ... }: {
    systemd.services.cleanup-flatpak = {
      enable = true;
      description = "Flatpak cleanup (unused runtimes and extensions)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "cleanup-flatpak" ''
          set -eu
          export PATH="${pkgs.flatpak}/bin:${pkgs.coreutils}/bin:$PATH"

          USAGE=$(df / | ${pkgs.gawk}/bin/awk 'NR==2 {gsub(/%/,""); print $5}')
          echo "Disk usage: $USAGE%"

          if [ "$USAGE" -ge 80 ]; then
            echo "Removing unused flatpak runtimes"
            flatpak uninstall --unused -y
          else
            echo "OK: no flatpak cleanup needed"
          fi
        '';
      };
    };

    systemd.timers.cleanup-flatpak = {
      enable = true;
      description = "Flatpak cleanup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "15min";
        Persistent = true;
      };
    };
  };
}
