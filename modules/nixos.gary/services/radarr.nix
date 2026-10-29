{
  flake.modules.generic.gary-service-radarr = _: {
    systemConstants.gary.services.radarr = {
      enable = true;
      port = 7878;
      subdomain = "radarr";
      description = "Radarr Movies";
      extraNginxConfig = "";
      firefox = {
        bookmark = true;
        folder = "Media";
      };
    };
  };

  flake.modules.nixos.gary-service-radarr =
    {
      config,
      lib,
      ...
    }:
    lib.mkIf config.systemConstants.gary.featureFlags.nixflix {
      nixflix.radarr = {
        enable = true;
        config.apiKey._secret = config.sops.secrets.radarr-api-key.path;
      };
    };
}
