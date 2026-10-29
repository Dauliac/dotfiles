{
  flake.modules.generic.gary-service-jellyfin = _: {
    systemConstants.gary.services.jellyfin = {
      enable = true;
      port = 8096;
      subdomain = "jellyfin";
      description = "Jellyfin Media Server";
      # Disable nginx response buffering so jellyfin's websocket + range
      # requests pass through cleanly for live transcoding + seek.
      extraNginxConfig = "proxy_buffering off;";
      firefox = {
        bookmark = true;
        folder = "Media";
      };
    };
  };

  flake.modules.nixos.gary-service-jellyfin =
    {
      config,
      lib,
      ...
    }:
    lib.mkIf config.systemConstants.gary.featureFlags.nixflix {
      nixflix.jellyfin = {
        enable = true;
        users.admin = {
          policy.isAdministrator = true;
          password._secret = config.sops.secrets.jellyfin-admin-password.path;
        };
      };
    };
}
