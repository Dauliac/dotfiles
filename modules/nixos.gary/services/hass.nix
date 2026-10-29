{
  # Catalog-only: backend wiring lives in modules/nixos.gary/home-assistant.nix.
  flake.modules.generic.gary-service-hass = _: {
    systemConstants.gary.services.hass = {
      enable = true;
      port = 8123;
      subdomain = "hass";
      description = "Home Assistant";
      # Websocket + Connection upgrade for the HA frontend's live push.
      extraNginxConfig = ''
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
      '';
      firefox = {
        bookmark = true;
        folder = "Home";
      };
    };
  };
}
