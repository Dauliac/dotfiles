# Firefox bookmarks configuration
# Includes auto-generated bookmarks from local services
{ lib, ... }:
let
  inherit (lib) mkIf mkAfter filterAttrs mapAttrsToList;
in
{
  config.dotfiles.home.userModules.gary = mkAfter [
    (
      { config, ... }:
      let
        cfg = config.dotfiles.gary.firefox;
        protocol = if cfg.useTLS then "https" else "http";

        # Generate bookmarks from local services
        enabledServices = filterAttrs (_: svc: svc.enable) cfg.localServices;
        serviceBookmarks = mapAttrsToList (
          name: svc: {
            name = svc.description;
            url = "${protocol}://${svc.subdomain}.${cfg.domain}";
          }
        ) enabledServices;

        # Static streaming bookmarks
        streamingBookmarks = [
          { name = "MyCanal"; url = "https://www.mycanal.fr/"; }
          { name = "Netflix"; url = "https://www.netflix.com/"; }
          { name = "Disney+"; url = "https://www.disneyplus.com"; }
          { name = "Paramount"; url = "https://www.paramountplus.com/"; }
          { name = "Crunchyroll"; url = "https://www.crunchyroll.com/"; }
          { name = "Arte"; url = "https://www.arte.tv/fr/"; }
          { name = "TF1"; url = "https://www.tf1.fr/"; }
          { name = "M6"; url = "https://www.m6.fr/"; }
          { name = "Pluto TV"; url = "https://pluto.tv/"; }
        ];

        # Static music bookmarks
        musicBookmarks = [
          { name = "Spotify"; url = "https://www.spotify.com/"; }
          { name = "Deezer"; url = "https://www.deezer.com/"; }
          { name = "YouTube"; url = "https://www.youtube.com/"; }
        ];

        # Static utility bookmarks
        utilityBookmarks = [
          { name = "Spliiit"; url = "https://www.spliiit.com/"; }
        ];
      in
      mkIf cfg.enable {
        programs.firefox.profiles.default.bookmarks = {
          force = true;
          settings = [
            {
              name = "Bar";
              toolbar = true;
              bookmarks =
                # Local services first (auto-generated)
                serviceBookmarks
                # Then streaming
                ++ streamingBookmarks
                # Then music
                ++ musicBookmarks
                # Then utilities
                ++ utilityBookmarks;
            }
          ];
        };
      }
    )
  ];
}
