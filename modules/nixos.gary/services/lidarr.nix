{
  flake.modules.generic.gary-service-lidarr = _: {
    systemConstants.gary.services.lidarr = {
      enable = true;
      port = 8686;
      subdomain = "lidarr";
      description = "Lidarr Music";
      extraNginxConfig = "";
      firefox = {
        bookmark = true;
        folder = "Media";
      };
    };
  };

  flake.modules.nixos.gary-service-lidarr =
    {
      config,
      lib,
      ...
    }:
    lib.mkIf config.systemConstants.gary.featureFlags.nixflix {
      nixflix.lidarr = {
        enable = true;
        config.apiKey._secret = config.sops.secrets.lidarr-api-key.path;
      };
    };
}
