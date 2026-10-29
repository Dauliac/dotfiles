{
  # Firefox pinned on workspace 1, auto-started, locked.
  #
  # `appId` is a regex because Firefox's Wayland app-id has shipped as
  # both `firefox` and `Firefox` across versions and distros; the
  # case-insensitive form here catches both. XWayland Firefox would
  # show up as `Firefox` (class), which also matches.
  flake.modules.homeManager.niri-kiosk = { pkgs, ... }: {
    myNiri.kiosk.apps.firefox = {
      workspaceName = "firefox";
      workspaceIndex = 1;
      appId = "(?i)^firefox$";
      command = "${pkgs.firefox}/bin/firefox";
      # Pin to the firefox workspace and open the window maximized
      # (equivalent to the Mod+F / maximize-column keybind). Fullscreen
      # was dropped in 6903636 because it hid the noctalia bar; plain
      # tiled was too narrow. Maximized fills the monitor minus the
      # reserved bar area, which is the kiosk brief.
      fullscreen = false;
      maximized = true;
      enforce = true;
    };
  };
}
