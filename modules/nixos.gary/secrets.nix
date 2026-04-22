{
  flake.modules.nixos.gary-secrets = {
    sops.secrets.gary_hashed_password = {
      sopsFile = ../../secrets/passwords/gary.enc;
      format = "json";
      key = "data";
    };
    sops.secrets.sonarr-api-key = { };
    sops.secrets.radarr-api-key = { };
    sops.secrets.lidarr-api-key = { };
    sops.secrets.prowlarr-api-key = { };
    sops.secrets.jellyseerr-api-key = { };
    sops.secrets.jellyfin-admin-password = { };
  };
}
