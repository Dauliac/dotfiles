{
  # Catalog-only.  Not in upstream nixflix; the backend service lives
  # outside the arr pipeline for now.
  flake.modules.generic.gary-service-bazarr = _: {
    systemConstants.gary.services.bazarr = {
      enable = true;
      port = 6767;
      subdomain = "bazarr";
      description = "Bazarr Subtitles";
      extraNginxConfig = "";
      firefox = {
        bookmark = true;
        folder = "Media";
      };
    };
  };
}
