{
  flake.modules.nixos.gary-mosquitto =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (config.systemConstants) gary;
    in
    lib.mkIf gary.featureFlags.mosquitto {
      services.mosquitto = {
        enable = true;
        listeners = [
          {
            inherit (gary.mosquitto) port;
            address = gary.mosquitto.listener;
            settings.allow_anonymous = false;
            users = {
              homeassistant = {
                acl = [ "readwrite #" ];
                passwordFile = config.sops.secrets.mqtt-homeassistant-password.path;
              };
              zigbee2mqtt = {
                acl = [ "readwrite #" ];
                passwordFile = config.sops.secrets.mqtt-zigbee2mqtt-password.path;
              };
              esphome = {
                acl = [ "readwrite #" ];
                passwordFile = config.sops.secrets.mqtt-esphome-password.path;
              };
            };
          }
        ];
      };

      networking.firewall.interfaces.${gary.network.interface}.allowedTCPPorts = [
        gary.mosquitto.port
      ];
    };
}
