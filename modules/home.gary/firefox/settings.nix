{
  flake.modules.homeManager.user-gary = { config, ... }: {
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

        # Vertical tabs via the Firefox 136+ "sidebar revamp" sidebar. The
        # auto-hide you noticed comes from the new sidebar collapsing by
        # default; flipping verticalTabs on moves the tab strip into that
        # sidebar so it is vertical when expanded and auto-hidden when not.
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;
        # Keep the sidebar visible by default (tabs always on screen); flip
        # to "hide-sidebar" to let it auto-collapse to an edge button.
        "sidebar.visibility" = "always-show";
        "sidebar.expandOnHover" = true;
        # Hide the AI chatbot entry in the sidebar / tools menu.
        "browser.ml.chat.enabled" = false;
        "browser.ml.chat.hideLocalhost" = true;
        "sidebar.main.tools" = "history,bookmarks";
        # Hide the "Tabs from other devices" (synced tabs) sidebar entry.
        "services.sync.engine.tabs" = false;
        "browser.tabs.firefox-view" = false;
      };
    };
  };
}
