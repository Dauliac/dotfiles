{
  flake.modules.nixos.gary-bluetooth-hub =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.systemConstants) gary;
      inherit (gary) bluetooth;
    in
    lib.mkIf gary.featureFlags.bluetoothHub {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Enable = "Source,Sink,Media,Socket";
            Discoverable = bluetooth.alwaysDiscoverable;
            DiscoverableTimeout = if bluetooth.alwaysDiscoverable then 0 else 180;
            Pairable = true;
            PairableTimeout = 0;
            Name = bluetooth.deviceName;
            Class = "0x20041C";
            Experimental = true;
            FastConnectable = true;
            MultiProfile = "multiple";
          };
          Policy.AutoEnable = true;
        };
      };

      services.pipewire = {
        enable = true;
        wireplumber = {
          enable = true;
          extraConfig = {
            "10-bluetooth" = {
              "monitor.bluez.properties" = {
                "bluez5.enable-sbc-xq" = true;
                "bluez5.enable-msbc" = true;
                "bluez5.enable-hw-volume" = true;
                "bluez5.codecs" = bluetooth.codecs;
                "bluez5.roles" = [
                  "a2dp_sink"
                  "a2dp_source"
                  "bap_sink"
                  "bap_source"
                  "hsp_hs"
                  "hsp_ag"
                  "hfp_hf"
                  "hfp_ag"
                ];
                "bluez5.autoswitch-profile" = true;
                "bluez5.headset-roles" = [
                  "hsp_hs"
                  "hsp_ag"
                  "hfp_hf"
                  "hfp_ag"
                ];
              };
            };
            "11-audio-routing"."wireplumber.settings" = {
              "bluetooth.autoswitch-to-headset-profile" = false;
            };
          };
        };
      };

      environment.systemPackages = with pkgs; [
        bluez
        bluez-tools
        bluetuith
        # nixpkgs 26.05 removed `helvum` (unmaintained + CVE in dep); crosspipe
        # is the suggested successor.
        crosspipe
        pwvucontrol
      ];

      users.users.gary.extraGroups = [
        "audio"
        "bluetooth"
      ];

      systemd.services.bluetooth = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Restart = "always";
          RestartSec = 5;
        };
      };
    };
}
