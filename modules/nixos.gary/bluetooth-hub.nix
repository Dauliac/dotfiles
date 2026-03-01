{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (
      { pkgs, ... }:
      {
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
              DiscoverableTimeout = 0; # Always discoverable
              Pairable = true;
              PairableTimeout = 0;

              # Device name shown to other devices
              Name = "Gary Audio Hub";
              Class = "0x20041C"; # Audio device class

              # Experimental features for better codec support
              Experimental = true;

              # Fast reconnection
              FastConnectable = true;

              # Multi-profile support
              MultiProfile = "multiple";
            };

            Policy = {
              # Auto-enable devices on boot
              AutoEnable = true;
            };
          };
        };

        # PipeWire configuration for Bluetooth audio
        services.pipewire = {
          enable = true;

          # Enable Bluetooth audio support
          wireplumber = {
            enable = true;
            extraConfig = {
              # Bluetooth audio settings
              "10-bluetooth" = {
                "monitor.bluez.properties" = {
                  # Enable all Bluetooth audio features
                  "bluez5.enable-sbc-xq" = true;
                  "bluez5.enable-msbc" = true;
                  "bluez5.enable-hw-volume" = true;

                  # High quality codecs
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

                  # A2DP sink role (receive audio from phone/platine)
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

                  # Auto-connect on startup
                  "bluez5.autoswitch-profile" = true;

                  # Headset role for hands-free
                  "bluez5.headset-roles" = [
                    "hsp_hs"
                    "hsp_ag"
                    "hfp_hf"
                    "hfp_ag"
                  ];
                };
              };

              # Default audio routing
              "11-audio-routing" = {
                "wireplumber.settings" = {
                  # Auto-switch to new Bluetooth devices
                  "bluetooth.autoswitch-to-headset-profile" = false;
                };
              };
            };
          };
        };

        # Useful tools for Bluetooth and audio management
        environment.systemPackages = with pkgs; [
          bluez
          bluez-tools
          bluetuith # TUI Bluetooth manager

          # Audio routing GUI
          helvum # Visual PipeWire patchbay - drag & drop audio routing
          pwvucontrol # Modern PipeWire volume control
        ];

        # Ensure user can manage Bluetooth
        users.users.gary.extraGroups = [ "audio" "bluetooth" ];

        # Keep Bluetooth service running
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
