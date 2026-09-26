{ ... }:
{
  # Screen-share backend for niri on Debian.
  #
  # niri implements org.gnome.Mutter.ScreenCast, so xdg-desktop-portal routes
  # any Wayland screencast request (Vesktop, Chromium, browser Meet/Zoom, OBS
  # via PipeWire) through xdg-desktop-portal-gnome. Debian's `niri`
  # metapackage does NOT pull it — must be installed explicitly, otherwise
  # ScreenCast silently returns "no sources available".
  #
  # This module contributes an INLINE ansnix role rather than appending to
  # `apt-packages.packages`. The reason: ansnix types freeform attrs as
  # `types.anything`, whose merge function calls `mergeOneOption` for lists —
  # so `packages = [ ... ]` in two modules is a conflict, not a concat.
  # A dedicated role with its own `tasks` sidesteps the merge entirely.
  #
  # Debian-only. NixOS hosts get the ScreenCast backend via
  # xdg.portal.extraPortals (see modules/nixos-*.gary etc.).
  flake.modules.systemManager.screen-share = { ... }: {
    ansnix.roles.screen-share-portal = {
      # Sequenced right after apt-packages (priority 100) so the base apt
      # cache is already updated by the time this role runs.
      priority = 105;
      after = [ "apt-packages" ];
      tasks = [
        {
          name = "screen-share | install xdg-desktop-portal-gnome (ScreenCast for niri)";
          "ansible.builtin.apt" = {
            name = [ "xdg-desktop-portal-gnome" ];
            state = "present";
          };
        }
      ];
    };
  };
}
