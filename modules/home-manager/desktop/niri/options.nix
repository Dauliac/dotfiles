{
  # Per-desk output presets. Layouts under ./layouts/*.nix each register
  # a `programs.niri.settings.outputs` block guarded on this enum, so only
  # one preset is active at a time. Extend the enum when adding a new
  # setup (see ./layouts/stackedExt.nix for the shape).
  flake.modules.homeManager.niri =
    { lib, ... }:
    {
      options.myNiri.deskSetup = lib.mkOption {
        type = lib.types.enum [ "stackedExt" ];
        default = "stackedExt";
        description = ''
          Which physical monitor arrangement is currently plugged in.
          Selects the matching `outputs` preset under
          `modules/home-manager/desktop/niri/layouts/`.
        '';
      };
    };
}
