{
  # Shared nixflix settings.  Per-service wiring (sonarr/radarr/lidarr/
  # prowlarr/jellyfin/seerr enable + apiKey) lives in
  # modules/nixos.gary/services/<name>.nix, so the catalog entry, the
  # firefox bookmark metadata, and the nixflix backend declaration are
  # colocated in one dendritic aspect per service.
  flake.modules.nixos.gary-nixflix =
    {
      config,
      lib,
      ...
    }:
    lib.mkIf config.systemConstants.gary.featureFlags.nixflix {
      nixflix = {
        enable = true;
        mediaDir = "/data/media";
        stateDir = "/data/.state/nixflix";
        # gary-acme owns public vhosts; nixflix's bundled nginx would
        # race with it over port 80/443 if left on.
        nginx.enable = false;
        postgres.enable = true;
      };
    };
}
