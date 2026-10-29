{
  # Catalog-only: backend wiring lives in modules/nixos.gary/esphome.nix.
  flake.modules.generic.gary-service-esphome = _: {
    systemConstants.gary.services.esphome = {
      enable = true;
      port = 6052;
      subdomain = "esphome";
      description = "ESPHome Dashboard";
      extraNginxConfig = "";
      firefox = {
        bookmark = true;
        folder = "Home";
      };
    };
  };
}
