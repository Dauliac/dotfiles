{
  # Workspace lock enforcer.
  #
  # niri has no first-class "exclusive workspace" primitive, so we
  # synthesise it from the event stream:
  #
  #   `niri msg --json event-stream` emits a line per compositor event.
  #   For every WindowOpenedOrChanged event, we:
  #
  #     1. Resolve the window's app-id and current workspace name.
  #     2. If (app-id matches a kiosk entry) and (workspace != kiosk
  #        workspace) → move the window back home.
  #     3. If (workspace is a kiosk workspace) and (app-id does not
  #        match that kiosk's regex) → evict the window to the
  #        fallback workspace.
  #
  # The daemon is a single awk-free jq pipeline so there are no
  # per-event shells and no busy loop. One socket connection, one
  # process, one journal stream.
  #
  # Enabled only when at least one kiosk app has `enforce = true`.
  flake.modules.homeManager.niri-kiosk =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      kiosk = config.myNiri.kiosk;
      enforcedApps = lib.filterAttrs (_: a: a.enforce) kiosk.apps;
      anyEnforced = enforcedApps != { };

      # Table consumed by the daemon:
      #   { "workspaceName": "app-id regex", ... }
      kioskTableJson = builtins.toJSON (
        lib.mapAttrs' (
          _name: app: lib.nameValuePair app.workspaceName app.appId
        ) enforcedApps
      );

      enforcerScript = pkgs.writeShellApplication {
        name = "niri-kiosk-enforcer";
        runtimeInputs = [
          pkgs.niri
          pkgs.jq
          pkgs.coreutils
        ];
        text = ''
          set -euo pipefail

          FALLBACK=${lib.escapeShellArg kiosk.fallbackWorkspace}
          # Attribute: workspace-name -> app-id regex.
          KIOSK_JSON=${lib.escapeShellArg kioskTableJson}

          echo "$KIOSK_JSON" | jq -e . >/dev/null

          move_to() {
            # $1 = window id, $2 = workspace name
            niri msg action move-window-to-workspace \
              --window-id "$1" \
              --workspace "$2" || true
          }

          # The window object exposes `workspace_id` (integer), not the
          # workspace name  -  so every tick we also fetch the workspace
          # table and join id -> name in jq. Keeping the join
          # server-side (one jq, one pass) avoids per-window shells.
          niri msg --json event-stream | while read -r _event; do
            windows=$(niri msg --json windows)
            workspaces=$(niri msg --json workspaces)

            # Decisions is a JSON array of
            #   { wid, action: "home"|"evict", target: "<workspace name>" }
            # produced server-side so the shell loop stays tiny.
            decisions=$(
              jq -n -c \
                --argjson kiosk "$KIOSK_JSON" \
                --argjson windows "$windows" \
                --argjson workspaces "$workspaces" \
                --arg fallback "$FALLBACK" '
                  # id -> name map
                  ($workspaces | map({(.id | tostring): .name}) | add) as $wsname
                  | $windows[]
                  | . as $w
                  | ($w.app_id // "") as $aid
                  | ($wsname[($w.workspace_id | tostring)] // "") as $wsn
                  | ($kiosk | to_entries | map(select($aid | test(.value))) | (.[0].key // "")) as $home_ws
                  | ($kiosk[$wsn] // "") as $ws_regex
                  | if ($home_ws != "" and $wsn != $home_ws) then
                      { wid: $w.id, action: "home", target: $home_ws }
                    elif ($ws_regex != "" and $home_ws == "") then
                      { wid: $w.id, action: "evict", target: $fallback }
                    else empty end
                '
            )

            echo "$decisions" | while read -r d; do
              [ -z "$d" ] && continue
              wid=$(echo "$d" | jq -r '.wid')
              target=$(echo "$d" | jq -r '.target')
              move_to "$wid" "$target"
            done
          done
        '';
      };
    in
    lib.mkIf anyEnforced {
      systemd.user.services.niri-kiosk-enforcer = {
        Unit = {
          Description = "niri kiosk workspace lock enforcer";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${enforcerScript}/bin/niri-kiosk-enforcer";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
