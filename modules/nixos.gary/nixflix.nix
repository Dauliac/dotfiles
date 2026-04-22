{
  flake.modules.nixos.gary-nixflix =
    { config, lib, ... }:
    lib.mkIf config.systemConstants.gary.featureFlags.nixflix {
      nixflix = {
        enable = true;

        mediaDir = "/data/media";
        stateDir = "/data/.state/nixflix";

        nginx.enable = true;
        postgres.enable = true;

        sonarr = {
          enable = true;
          config.apiKey = { _secret = config.sops.secrets.sonarr-api-key.path; };
        };

        radarr = {
          enable = true;
          config.apiKey = { _secret = config.sops.secrets.radarr-api-key.path; };
        };

        lidarr = {
          enable = true;
          config.apiKey = { _secret = config.sops.secrets.lidarr-api-key.path; };
        };

        prowlarr = {
          enable = true;
          config.apiKey = { _secret = config.sops.secrets.prowlarr-api-key.path; };
        };

        jellyfin = {
          enable = true;
          users.admin = {
            policy.isAdministrator = true;
            password = { _secret = config.sops.secrets.jellyfin-admin-password.path; };
          };
        };

        seerr = {
          enable = true;
          apiKey = { _secret = config.sops.secrets.jellyseerr-api-key.path; };
        };
      };
    };
}
