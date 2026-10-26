{
  # gary-specific window routing. firefox is owned by the kiosk module
  # (modules/home-manager/desktop/niri/kiosk/apps/firefox.nix) which emits
  # its own window-rule pinning firefox to the "firefox" workspace. The
  # rules here cover the other TV apps.
  #
  # These append to the shared window-rules list in
  # modules/home-manager/desktop/niri/settings.nix - matches are evaluated
  # top-to-bottom per niri's semantics, so an entry here does not shadow
  # a kiosk entry declared earlier.
  flake.modules.homeManager.user-gary = {
    programs.niri.settings.window-rules = [
      {
        matches = [ { app-id = ''^chromium$''; } ];
        open-maximized = true;
        open-on-workspace = "browser";
      }
      {
        matches = [ { app-id = ''^steam$''; } ];
        open-on-workspace = "apps";
      }
      {
        matches = [ { app-id = ''^Spotify$''; } ];
        open-on-workspace = "media";
      }
    ];
  };
}
