# Firefox profile settings
# Browser behavior and UI configuration
{ lib, ... }:
{
  config.dotfiles.home.userModules.gary = lib.mkAfter [
    (
      { config, ... }:
      let
        cfg = config.dotfiles.gary.firefox;
      in
      lib.mkIf cfg.enable {
        programs.firefox.profiles.default = {
          isDefault = true;
          settings = {
            # Extension settings
            "extensions.webextPermissionPrompts" = false;
            "extensions.postDownloadThirdPartyPrompt" = false;

            # UI scale
            "layout.css.devPixelsPerPx" = cfg.scale;

            # Always show bookmarks bar
            "browser.toolbars.bookmarks.visibility" = "always";
          };
        };
      }
    )
  ];
}
