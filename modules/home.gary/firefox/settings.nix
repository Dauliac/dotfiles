{
  flake.modules.homeManager.user-gary = {
    programs.firefox.profiles.default = {
      isDefault = true;
      settings = {
        "extensions.webextPermissionPrompts" = false;
        "extensions.postDownloadThirdPartyPrompt" = false;
        "layout.css.devPixelsPerPx" = "3";
        "browser.toolbars.bookmarks.visibility" = "always";
      };
    };
  };
}
