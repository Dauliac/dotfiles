# Bluetooth audio hub configuration
# Makes gary act as a Bluetooth audio receiver
# Defines options AND implementation together
{ lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types mkIf mkAfter;
in
{
  # ════════════════════════════════════════════
  # OPTIONS
  # ════════════════════════════════════════════
  options.dotfiles.gary.bluetooth = {
    enable = mkEnableOption "Bluetooth audio hub";

    deviceName = mkOption {
      type = types.str;
      default = "Gary Audio Hub";
      description = "Bluetooth device name shown to other devices";
    };

    alwaysDiscoverable = mkOption {
      type = types.bool;
      default = true;
      description = "Keep device always discoverable";
    };

    codecs = mkOption {
      type = types.listOf types.str;
      default = [
        "sbc"
        "sbc_xq"
        "aac"
        "ldac"
        "aptx"
        "aptx_hd"
        "aptx_ll"
        "aptx_ll_duplex"
      ];
      description = "Enabled Bluetooth audio codecs";
    };
  };

  # ════════════════════════════════════════════
  # IMPLEMENTATION
  # ════════════════════════════════════════════
  config.dotfiles.nixos.hostModules.gary = mkAfter [
    (
      { config, pkgs, ... }:
      let
        cfg = config.dotfiles.gary.bluetooth;
      in
      mkIf cfg.enable {
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings = {
            General = {
              Enable = "Source,Sink,Media,Socket";
              Discoverable = cfg.alwaysDiscoverable;
              DiscoverableTimeout = if cfg.alwaysDiscoverable then 0 else 180;
              Pairable = true;
              PairableTimeout = 0;
              Name = cfg.deviceName;
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
                  "bluez5.codecs" = cfg.codecs;
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
          helvum
          pwvucontrol
        ];

        users.users.gary.extraGroups = [ "audio" "bluetooth" ];

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
