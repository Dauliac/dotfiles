{
  # gary workspace plan (TV box):
  #   01  firefox   (owned by myNiri.kiosk.apps.firefox - see
  #                  modules/home-manager/desktop/niri/kiosk/apps/firefox.nix,
  #                  mkForces slot "01")
  #   02  media     (Spotify / future TV apps)
  #   03  browser   (chromium rule routes here; secondary firefox windows)
  #   04  apps      (steam + misc GUIs)
  #
  # The shared base at modules/home-manager/desktop/niri/settings.nix also
  # declares workspaces "05".."09" with generic numeric names. We leave
  # those in place rather than fight the merge; gary ends up with nine
  # workspaces where only the first four have meaningful names, which is
  # harmless. Firefox lands on "01" regardless.
  flake.modules.homeManager.user-gary =
    { lib, ... }:
    {
      programs.niri.settings.workspaces = {
        "02" = lib.mkForce { name = "media"; };
        "03" = lib.mkForce { name = "browser"; };
        "04" = lib.mkForce { name = "apps"; };
      };
    };
}
