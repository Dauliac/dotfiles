{
  # Catalog-only: backend wiring lives in modules/nixos.gary/adguard.nix.
  flake.modules.generic.gary-service-adguard = _: {
    systemConstants.gary.services.adguard = {
      enable = true;
      port = 3000;
      subdomain = "adguard";
      description = "AdGuard Home DNS";
      extraNginxConfig = "";
      firefox = {
        bookmark = true;
        folder = "Home";
      };
    };
  };
}
