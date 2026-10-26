{
  # gary-specific layout tweaks on top of the shared defaults in
  # modules/home-manager/desktop/niri/settings.nix. Only the pieces
  # the TV box actually diverges on are listed here (bigger gaps for
  # readability at viewing distance). Everything else - overview zoom,
  # shadow, screenshot path, geometry corner radius - comes from the
  # shared leaf and does not need re-declaring.
  flake.modules.homeManager.user-gary =
    { lib, ... }:
    {
      programs.niri.settings.layout.gaps = lib.mkForce 10;
    };
}
