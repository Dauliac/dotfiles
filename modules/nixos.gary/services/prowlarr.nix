{
  flake.modules.generic.gary-service-prowlarr = _: {
    systemConstants.gary.services.prowlarr = {
      enable = true;
      port = 9696;
      subdomain = "prowlarr";
      description = "Prowlarr Indexers";
      extraNginxConfig = "";
      firefox = {
        bookmark = true;
        folder = "Media";
      };
    };
  };

  flake.modules.nixos.gary-service-prowlarr =
    {
      config,
      lib,
      ...
    }:
    lib.mkIf config.systemConstants.gary.featureFlags.nixflix {
      nixflix.prowlarr = {
        enable = true;
        config.apiKey._secret = config.sops.secrets.prowlarr-api-key.path;
      };
    };
}
