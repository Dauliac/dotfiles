{
  # Kiosk / "TV app manager" model for niri.
  #
  # One niri workspace per declared app:
  #   - workspace is named after the app
  #   - app is spawned by a systemd user unit (Restart=always, PartOf
  #     graphical-session.target), so it survives crash and session cycle
  #   - app opens fullscreen and is routed to its workspace via window-rules
  #   - an optional IPC enforcer keeps the lock symmetric: any stray
  #     window that lands on a kiosk workspace is punted elsewhere, and
  #     the kiosk window is bounced back to its home workspace if the
  #     user tries to drag it out
  #
  # The option tree is the single source of truth. workspaces.nix,
  # rules.nix, services.nix and enforcer.nix each read it and emit
  # their slice of niri / systemd config.
  flake.modules.homeManager.niri-kiosk =
    { lib, ... }:
    let
      appSubmodule = lib.types.submodule (
        { name, ... }:
        {
          options = {
            workspaceName = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = ''
                niri workspace name. Window-rules route the app here via
                `open-on-workspace`. Defaults to the attribute name.
              '';
            };

            workspaceIndex = lib.mkOption {
              type = lib.types.ints.between 1 99;
              description = ''
                Position of this workspace in the niri workspace list
                (1-based). Becomes the two-digit sort key niri uses
                internally (`"01"`, `"02"`, ...).
              '';
            };

            appId = lib.mkOption {
              type = lib.types.str;
              description = ''
                Regex matched against the window `app-id`
                (Wayland xdg-shell) or XWayland class. Used by both the
                window-rule and the enforcer to decide "is this the
                kiosk app or an intruder".
              '';
            };

            command = lib.mkOption {
              type = lib.types.str;
              description = ''
                Shell command run by the per-app systemd user service.
                Pass the fully-resolved binary path (e.g.
                `''${pkgs.firefox}/bin/firefox`), not a bare name.
              '';
            };

            fullscreen = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Open the window fullscreen (niri window-rule
                `open-fullscreen`). TV-app default is on.
              '';
            };

            enforce = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Enable the IPC enforcer for this workspace:
                  - foreign windows that land here are moved to the
                    fallback workspace
                  - the kiosk window is moved back here if it ever
                    ends up elsewhere
                Turn off to keep the auto-start + routing behaviour
                but allow the user to co-locate windows manually.
              '';
            };
          };
        }
      );
    in
    {
      options.myNiri.kiosk = {
        apps = lib.mkOption {
          type = lib.types.attrsOf appSubmodule;
          default = { };
          description = ''
            Set of kiosk-managed apps. Each entry owns one workspace.
            Define apps as dendritic leaves under
            `./kiosk/apps/<name>.nix`.
          '';
        };

        fallbackWorkspace = lib.mkOption {
          type = lib.types.str;
          default = "1";
          description = ''
            Workspace name the enforcer sends intruders to when it
            evicts them from a kiosk workspace. Must exist in
            `programs.niri.settings.workspaces` (any non-kiosk one is
            fine).
          '';
        };
      };
    };
}
