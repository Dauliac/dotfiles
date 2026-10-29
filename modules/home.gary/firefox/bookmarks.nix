{
  flake.modules.homeManager.user-gary =
    {
      config,
      osConfig ? null,
      lib,
      ...
    }:
    let
      # Prefer the NixOS-side view (osConfig) so VM-mode overrides to the
      # catalog, domain, and acme feature flag land in bookmarks without
      # having to duplicate the override into HM scope.  Standalone HM
      # installs (no osConfig) fall back to the HM scope's own view.
      gary = if osConfig != null then osConfig.systemConstants.gary else config.systemConstants.gary;
      useTLS = gary.featureFlags.acme;
      domain = if useTLS then gary.domain.public else gary.domain.local;
      protocol = if useTLS then "https" else "http";

      # Only services with firefox.bookmark = true become bookmarks.
      # The firefox sub-attr is set in modules/nixos.gary/services/<name>.nix.
      bookmarkedServices = lib.filterAttrs (
        _: svc: svc.enable && (svc.firefox or { bookmark = false; }).bookmark
      ) gary.services;
      serviceBookmarks = lib.mapAttrsToList (_: svc: {
        name = svc.description;
        url = "${protocol}://${svc.subdomain}.${domain}";
      }) bookmarkedServices;

      streamingBookmarks = [
        {
          name = "MyCanal";
          url = "https://www.mycanal.fr/";
        }
        {
          name = "Netflix";
          url = "https://www.netflix.com/";
        }
        {
          name = "Disney+";
          url = "https://www.disneyplus.com";
        }
        {
          name = "Paramount";
          url = "https://www.paramountplus.com/";
        }
        {
          name = "Crunchyroll";
          url = "https://www.crunchyroll.com/";
        }
        {
          name = "Arte";
          url = "https://www.arte.tv/fr/";
        }
        {
          name = "TF1";
          url = "https://www.tf1.fr/";
        }
        {
          name = "M6";
          url = "https://www.m6.fr/";
        }
        {
          name = "Pluto TV";
          url = "https://pluto.tv/";
        }
      ];

      musicBookmarks = [
        {
          name = "Spotify";
          url = "https://www.spotify.com/";
        }
        {
          name = "Deezer";
          url = "https://www.deezer.com/";
        }
        {
          name = "YouTube";
          url = "https://www.youtube.com/";
        }
      ];

      utilityBookmarks = [
        {
          name = "Spliiit";
          url = "https://www.spliiit.com/";
        }
      ];
    in
    {
      programs.firefox.profiles.default.bookmarks = {
        force = true;
        settings = [
          {
            name = "Bar";
            toolbar = true;
            bookmarks = serviceBookmarks ++ streamingBookmarks ++ musicBookmarks ++ utilityBookmarks;
          }
        ];
      };
    };
}
