{
  # Catalog entry: `generic` scope so both NixOS (reverse-proxy, acme,
  # cloudflared, nixflix) and home-manager (firefox bookmarks) see it.
  flake.modules.generic.gary-service-sonarr = _: {
    systemConstants.gary.services.sonarr = {
      enable = true;
      port = 8989;
      subdomain = "sonarr";
      description = "Sonarr TV Shows";
      extraNginxConfig = "";
      firefox = {
        bookmark = true;
        folder = "Media";
      };
    };
  };

  # Backend wiring: NixOS scope only.  Guarded by the feature flag so a
  # VM-mode build (nixflix off, standalone arr services in vm/arr.nix)
  # does not try to resolve the sops path.
  flake.modules.nixos.gary-service-sonarr =
    {
      config,
      lib,
      ...
    }:
    lib.mkIf config.systemConstants.gary.featureFlags.nixflix {
      nixflix.sonarr = {
        enable = true;
        config.apiKey._secret = config.sops.secrets.sonarr-api-key.path;
      };
    };
}
