{
  # Firefox pinned on workspace 1, auto-started, locked.
  #
  # `appId` is a regex because Firefox's Wayland app-id has shipped as
  # both `firefox` and `Firefox` across versions and distros; the
  # case-insensitive form here catches both. XWayland Firefox would
  # show up as `Firefox` (class), which also matches.
  flake.modules.homeManager.niri-kiosk =
    { pkgs, ... }:
    {
      myNiri.kiosk.apps.firefox = {
        workspaceName = "firefox";
        workspaceIndex = 1;
        appId = "(?i)^firefox$";
        command = "${pkgs.firefox}/bin/firefox";
        fullscreen = true;
        enforce = true;
      };
    };
}
