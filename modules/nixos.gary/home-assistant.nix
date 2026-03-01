{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (_: {
      services.home-assistant = {
        enable = true;
        openFirewall = true; # Opens port 8123

        extraComponents = [
          # Lights
          "hue" # Philips Hue
          "yeelight" # Xiaomi Yeelight
          "wiz" # WiZ bulbs
          "tplink" # TP-Link Kasa
          "tradfri" # IKEA Tradfri

          # Zigbee/Z-Wave (if you have a coordinator)
          "zha" # Zigbee Home Automation
          "zwave_js" # Z-Wave JS

          # Music & Media
          "spotify"
          "cast" # Chromecast
          "dlna_dmr" # DLNA renderers
          "mpd" # Music Player Daemon
          "sonos"

          # Network & Discovery
          "ssdp"
          "zeroconf"
          "dhcp"

          # Useful integrations
          "mobile_app" # Home Assistant Companion app
          "esphome" # ESP-based devices
          "mqtt" # MQTT broker support
          "webhook"
          "bluetooth"

          # System monitoring
          "systemmonitor"
        ];

        config = {
          homeassistant = {
            name = "Home";
            unit_system = "metric";
            time_zone = "Europe/Paris";
          };

          # Enable default integrations
          default_config = { };

          # HTTP configuration
          http = {
            server_port = 8123;
            ip_ban_enabled = true;
            login_attempts_threshold = 5;
          };
        };
      };

      # Recommended: enable avahi for device discovery
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };

      # For Bluetooth support
      hardware.bluetooth.enable = lib.mkDefault true;
    })
  ];
}
