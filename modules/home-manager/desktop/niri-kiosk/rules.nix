{
  # Window-rule slice derived from `myNiri.kiosk.apps`.
  #
  # Each kiosk app contributes one rule routing its windows to the
  # dedicated workspace and (by default) opening them fullscreen. The
  # rules append to any `window-rules` already declared in settings.nix
  # since nix merges list-valued options via concatenation when the
  # same key is set across modules.
  flake.modules.homeManager.niri-kiosk =
    { config, lib, ... }:
    let
      kioskApps = config.myNiri.kiosk.apps;

      ruleFor = _name: app: {
        matches = [ { app-id = app.appId; } ];
        open-on-workspace = app.workspaceName;
        open-fullscreen = app.fullscreen;
      };

      kioskRules = lib.mapAttrsToList ruleFor kioskApps;
    in
    {
      programs.niri.settings.window-rules = kioskRules;
    };
}
