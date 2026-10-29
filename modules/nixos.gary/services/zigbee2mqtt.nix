{
  # Catalog-only: backend wiring lives in modules/nixos.gary/zigbee2mqtt.nix.
  flake.modules.generic.gary-service-zigbee2mqtt = _: {
    systemConstants.gary.services.zigbee2mqtt = {
      enable = true;
      # z2m frontend here to avoid clashing with the arr 5055-9696 range.
      port = 8082;
      subdomain = "zigbee2mqtt";
      description = "Zigbee2MQTT";
      extraNginxConfig = "";
      firefox = {
        bookmark = true;
        folder = "Home";
      };
    };
  };
}
