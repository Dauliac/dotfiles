{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (_: {
      sops = {
        secrets.gary_hashed_password = { };
        # Nixflix API keys
        secrets.sonarr-api-key = { };
        secrets.radarr-api-key = { };
        secrets.lidarr-api-key = { };
        secrets.prowlarr-api-key = { };
        secrets.jellyseerr-api-key = { };
        secrets.jellyfin-admin-password = { };
      };
    })
  ];
}
