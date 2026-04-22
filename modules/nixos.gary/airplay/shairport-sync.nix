{
  flake.modules.nixos.gary-airplay-shairport =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf mkForce optionals;
      gary = config.systemConstants.gary;
      audio = gary.airplay.audio;
      deviceName = gary.airplay.deviceName;
    in
    lib.mkIf (gary.featureFlags.airplay && gary.featureFlags.airplayAudio) {
      nixpkgs.overlays = optionals audio.airplay2 [
        (_final: prev: {
          shairport-sync = prev.shairport-sync.override { enableAirplay2 = true; };
        })
      ];

      systemd.services.nqptp = mkIf audio.airplay2 {
        description = "PTP timing daemon for AirPlay 2";
        wantedBy = [ "multi-user.target" ];
        before = [ "shairport-sync.service" ];

        serviceConfig = {
          ExecStart = "${pkgs.nqptp}/bin/nqptp";
          Restart = "always";
          RestartSec = 5;
        };
      };

      environment.etc."shairport-sync.conf".source = mkForce (pkgs.writeText "shairport-sync.conf" ''
        general = {
          name = "${deviceName} Audio";
          interpolation = "auto";
          output_backend = "pw";
          volume_range_db = ${toString audio.volumeRangeDb};
        };

        sessioncontrol = {
          session_timeout = 20;
        };

        alsa = {
          mixer_control_name = "Master";
        };
      '');

      services.shairport-sync = {
        enable = true;
        openFirewall = true;
      };

      systemd.services.shairport-sync = {
        serviceConfig.ExecStart = mkForce "${pkgs.shairport-sync}/bin/shairport-sync -c /etc/shairport-sync.conf";
        after = [
          "avahi-daemon.service"
          "pipewire.service"
        ]
        ++ optionals audio.airplay2 [ "nqptp.service" ];
        requires = optionals audio.airplay2 [ "nqptp.service" ];
      };

      networking.firewall = {
        allowedTCPPorts = [ 5000 ];
        allowedUDPPortRanges = [
          { from = 6001; to = 6011; }
        ];
      };
    };
}
