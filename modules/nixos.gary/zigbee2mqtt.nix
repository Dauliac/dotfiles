{
  flake.modules.nixos.gary-zigbee2mqtt =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (config.systemConstants) gary;
      z2m = gary.services.zigbee2mqtt;
    in
    lib.mkIf gary.featureFlags.zigbee2mqtt {
      services.zigbee2mqtt = {
        enable = true;
        settings = {
          homeassistant = true;
          permit_join = false; # explicit pairing only, via UI

          mqtt = {
            server = "mqtt://127.0.0.1:${toString gary.mosquitto.port}";
            user = "zigbee2mqtt";
            password = "!/run/secrets/mqtt-zigbee2mqtt-password";
            base_topic = "zigbee2mqtt";
          };

          # USER MUST SET THIS after plugging in the coordinator. Common values:
          #   Sonoff ZBDongle-E:  /dev/serial/by-id/usb-Itead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_...
          #   Conbee II:          /dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_...
          serial.port = "/dev/ttyACM0";

          advanced = {
            channel = 15;
            log_level = "info";
          };

          frontend = {
            enabled = true;
            host = "127.0.0.1";
            inherit (z2m) port;
            auth_token = "!/run/secrets/zigbee2mqtt-frontend-token";
          };
        };
      };

      systemd.services.zigbee2mqtt = {
        after = [ "mosquitto.service" ];
        requires = [ "mosquitto.service" ];
      };
    };
}
