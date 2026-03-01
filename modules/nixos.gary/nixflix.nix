# Nixflix media server configuration for gary
{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    ({ config, ... }: {
      nixflix = {
        enable = true;

        # Media and state directories
        mediaDir = "/data/media";
        stateDir = "/data/.state/nixflix";

        # Infrastructure services
        nginx.enable = true;
        postgres.enable = true;

        # Media management - Arr stack
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

        # Media streaming
        jellyfin.enable = true;

        # Media requests
        jellyseerr = {
          enable = true;
          apiKey = { _secret = config.sops.secrets.jellyseerr-api-key.path; };
        };
      };
    })
  ];
}
