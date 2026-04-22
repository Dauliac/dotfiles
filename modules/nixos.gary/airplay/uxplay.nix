{
  flake.modules.nixos.gary-airplay-uxplay =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) optionalString;
      gary = config.systemConstants.gary;
      sm = gary.airplay.screenMirroring;
      deviceName = gary.airplay.deviceName;
    in
    lib.mkIf (gary.featureFlags.airplay && gary.featureFlags.airplayScreenMirroring) {
      environment.systemPackages = [
        pkgs.uxplay
        pkgs.gnomeExtensions.uxplay-control
      ];

      systemd.user.services.uxplay = {
        description = "UxPlay AirPlay Screen Mirroring Server";
        wantedBy = [ "graphical-session.target" ];
        after = [
          "graphical-session.target"
          "pipewire.service"
        ];

        serviceConfig = {
          ExecStart = builtins.concatStringsSep " " [
            "${pkgs.uxplay}/bin/uxplay"
            "-n '${deviceName} Screen'"
            "-s ${sm.resolution}"
            "-fps ${toString sm.fps}"
            (optionalString sm.lowLatency "-async")
            (optionalString sm.fullscreen "-fs")
            "-as pipewire"
          ];
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      networking.firewall = {
        allowedTCPPorts = [
          7000
          7001
          7100
        ];
        allowedUDPPorts = [
          6000
          6001
          7011
        ];
        allowedUDPPortRanges = [
          { from = 6000; to = 6100; }
          { from = 32768; to = 60999; }
        ];
      };
    };
}
