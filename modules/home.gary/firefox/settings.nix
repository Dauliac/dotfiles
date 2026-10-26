{
  flake.modules.homeManager.user-gary = { config, ... }:
    let
      inherit (config.systemConstants) gary;
      useTLS = gary.featureFlags.acme;
      domain = if useTLS then gary.domain.public else gary.domain.local;
      protocol = if useTLS then "https" else "http";

      svc = name: {
        url = "${protocol}://${gary.services.${name}.subdomain}.${domain}";
        label = gary.services.${name}.description;
      };

      # New Tab pinned shortcuts: *arr stack + Home Assistant + media.
      # Firefox stores pinned tiles as a JSON array in a string pref.
      pinnedTiles = [
        (svc "hass")
        (svc "adguard")
        (svc "jellyfin")
        (svc "jellyseerr")
        (svc "sonarr")
        (svc "radarr")
        (svc "prowlarr")
        (svc "bazarr")
        (svc "lidarr")
        (svc "esphome")
        { url = "https://www.mycanal.fr/"; label = "MyCanal"; }
        { url = "https://www.netflix.com/"; label = "Netflix"; }
      ];
    in
    {
    programs.firefox.profiles.default = {
      isDefault = true;
      settings = {
        "extensions.webextPermissionPrompts" = false;
        "extensions.postDownloadThirdPartyPrompt" = false;
        "extensions.autoDisableScopes" = 0;

        "browser.aboutwelcome.enabled" = false;
        "browser.startup.homepage_override.mstone" = "ignore";
        # Driven by the host's declared display scale (systemConstants.display)
        # so gary (TV) and the VM (laptop) pick different values from the
        # same single-source abstraction.
        "layout.css.devPixelsPerPx" = toString config.systemConstants.display.firefoxDevPixelsPerPx;
        "browser.toolbars.bookmarks.visibility" = "always";
        # Window density: Touch (0=normal, 1=compact, 2=touch). Gary runs on
        # a TV at living-room distance so the larger touch targets fit the
        # viewing geometry.
        "browser.uidensity" = 2;

        # Vertical tabs via the Firefox 136+ "sidebar revamp" sidebar. The
        # auto-hide you noticed comes from the new sidebar collapsing by
        # default; flipping verticalTabs on moves the tab strip into that
        # sidebar so it is vertical when expanded and auto-hidden when not.
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;
        # Use the smooth animated hover-expand mode (the "Expand sidebar on
        # hover" radio in Settings > General > Browser Layout), not the
        # non-animated "Hide sidebar" / toolbar-hide mode.
        "sidebar.visibility" = "expand-on-hover";
        "sidebar.expandOnHover" = true;
        "sidebar.animation.enabled" = true;
        # Hide the AI chatbot entry in the sidebar / tools menu.
        "browser.ml.chat.enabled" = false;
        "browser.ml.chat.hideLocalhost" = true;
        "sidebar.main.tools" = "history,bookmarks";
        # Hide the "Tabs from other devices" (synced tabs) sidebar entry.
        "services.sync.engine.tabs" = false;
        "browser.tabs.firefox-view" = false;

        # Pinned shortcuts on the New Tab page (built from gary.services so
        # the *arr stack / Home Assistant URLs follow ACME + domain flips).
        # feeds.topsites and the sponsored-tile toggles are locked at the
        # policy layer (see policies.nix).
        "browser.newtabpage.pinned" = builtins.toJSON pinnedTiles;
        "browser.newtabpage.activity-stream.topSitesRows" = 2;
      };
    };
  };
}
