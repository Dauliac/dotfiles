{
  # User-facing subdomain / bookmark label is "jellyseerr"; the nixflix
  # sub-module is called "seerr" upstream.
  flake.modules.generic.gary-service-jellyseerr = _: {
    systemConstants.gary.services.jellyseerr = {
      enable = true;
      port = 5055;
      subdomain = "jellyseerr";
      description = "Jellyseerr Requests";
      extraNginxConfig = "";
      firefox = {
        bookmark = true;
        folder = "Media";
      };
    };
  };

  flake.modules.nixos.gary-service-jellyseerr =
    {
      config,
      lib,
      ...
    }:
    lib.mkIf config.systemConstants.gary.featureFlags.nixflix {
      nixflix.seerr = {
        enable = true;
        apiKey._secret = config.sops.secrets.jellyseerr-api-key.path;
      };
    };
}
