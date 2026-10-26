{
  # gary (TV box) input tuning. US-only xkb (no French layout toggle on
  # a living-room TV), touchpad tap + natural scroll for the occasional
  # peripheral. Overrides the base French / three-layout wiring in
  # modules/home-manager/desktop/niri/settings.nix via mkForce on the
  # three xkb sub-options the base sets with plain assignments.
  flake.modules.homeManager.user-gary =
    { lib, ... }:
    {
      programs.niri.settings.input = {
        keyboard.xkb = {
          layout = lib.mkForce "us";
          variant = lib.mkForce "";
          options = lib.mkForce "";
        };
        keyboard.numlock = lib.mkForce true;
        touchpad = {
          tap = lib.mkForce true;
          natural-scroll = lib.mkForce true;
        };
      };
    };
}
