{
  # Catalog-only.  Nixflix supports qbittorrent via its torrentClients
  # submodule; wire that later if we move downloads into the arr pipeline.
  flake.modules.generic.gary-service-qbittorrent = _: {
    systemConstants.gary.services.qbittorrent = {
      enable = true;
      port = 8112;
      subdomain = "qbittorrent";
      description = "qBittorrent";
      extraNginxConfig = "";
      firefox = {
        bookmark = true;
        folder = "Media";
      };
    };
  };
}
