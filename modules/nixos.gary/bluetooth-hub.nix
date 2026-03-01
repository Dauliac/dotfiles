# Bluetooth audio hub configuration
# Makes gary act as a Bluetooth audio receiver
# Configuration comes from dotfiles.gary options
{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (
      { config, pkgs, ... }:
      let
        cfg = config.dotfiles.gary;
      in
      lib.mkIf cfg.bluetooth.enable {
        # Enhanced Bluetooth configuration for audio hub
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings = {
            General = {
              # Enable A2DP sink (receive audio)
              Enable = "Source,Sink,Media,Socket";

              # Make discoverable and pairable
              Discoverable = true;
              DiscoverableTimeout = 0;
              Pairable = true;
              PairableTimeout = 0;

              # Device name from options
              Name = cfg.bluetooth.deviceName;
              Class = "0x20041C"; # Audio device class

              Experimental = true;
              FastConnectable = true;
              MultiProfile = "multiple";
            };

            Policy.AutoEnable = true;
          };
        };

        # PipeWire configuration for Bluetooth audio
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
                  "bluez5.codecs" = [
                    "sbc"
                    "sbc_xq"
                    "aac"
                    "ldac"
                    "aptx"
                    "aptx_hd"
                    "aptx_ll"
                    "aptx_ll_duplex"
                  ];
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
              "11-audio-routing" = {
                "wireplumber.settings" = {
                  "bluetooth.autoswitch-to-headset-profile" = false;
                };
              };
            };
          };
        };

        # Bluetooth and audio management tools
        environment.systemPackages = with pkgs; [
          bluez
          bluez-tools
          bluetuith
          helvum
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
      }
    )
  ];
}
