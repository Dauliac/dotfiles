{
  # Materialise `myNiri.kiosk.apps` into niri's named-workspace table.
  #
  # niri sorts workspaces by their attribute key (settings.workspaces is
  # an attrset keyed by sort tag). We derive the sort tag from
  # `workspaceIndex` padded to two digits so the ordering stays stable
  # even as apps are added or removed. Non-kiosk workspaces (declared
  # in settings.nix with keys "01".."09") coexist as long as their
  # indices do not collide with kiosk ones.
  flake.modules.homeManager.niri-kiosk =
    { config, lib, ... }:
    let
      pad = n: if n < 10 then "0${toString n}" else toString n;

      kioskApps = config.myNiri.kiosk.apps;

      # mkForce so a kiosk entry wins over whatever settings.nix had at
      # the same sort tag. Picking the same `workspaceIndex` as an
      # existing static workspace is how you replace it with a kiosk
      # one (e.g. index 1 to swap workspace "1" for the firefox kiosk).
      kioskWorkspaces = lib.mapAttrs' (
        _name: app:
        lib.nameValuePair (pad app.workspaceIndex) (lib.mkForce {
          name = app.workspaceName;
        })
      ) kioskApps;
    in
    {
      programs.niri.settings.workspaces = kioskWorkspaces;
    };
}
