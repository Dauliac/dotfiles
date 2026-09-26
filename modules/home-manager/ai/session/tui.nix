{
  flake.modules.homeManager.ai-session-tui =
    { pkgs, ... }:
    let
      herdr-tui = pkgs.writeShellApplication {
        name = "herdr-tui";
        runtimeInputs = with pkgs; [
          herdr
          jq
          coreutils
          util-linux
        ];
        text = ''
          # herdr-tui — spawn context-aware TUIs (k9s, glab ci view, stu, ...)
          # in herdr splits, with per-pane auto-close.
          #
          # Layout rule:
          #   * One TUI  -> vertical split of the current pane.
          #   * N TUIs   -> new tab, alternating vertical/horizontal splits
          #                 (grid-open + grid-add per pane).

          usage() {
            cat >&2 <<'EOF'
          Usage:
            herdr-tui launch    [OPTIONS] -- <cmd> [args...]
            herdr-tui grid-open [--label TEXT]
            herdr-tui grid-add  <grid-id> [OPTIONS] -- <cmd> [args...]
            herdr-tui grid-close <grid-id>

          Subcommands:
            launch       Spawn <cmd> in a fresh vertical split of the current pane.
            grid-open    Create a new tab to host multiple TUIs. Prints the grid id.
            grid-add     Add a TUI to a grid, alternating vertical/horizontal splits.
            grid-close   Close the grid tab and every pane in it.

          Auto-close options (apply to launch and grid-add):
            --auto-close-on-idle SEC   Close after SEC seconds of no engagement.
                                       Engagement = pane focused OR scrolled up.
                                       Default: 60s.
            --auto-close-when 'SHELL'  Poll SHELL every 5s; close when it exits 0.
                                       Runs under sh -c. Composes with --on-idle.
            --auto-close-timeout SEC   Absolute cap; close after SEC seconds even
                                       if the user is still engaged.
            --keep                     Never auto-close; leave pane open forever.

          Other options:
            --label TEXT   Set a label on the created pane / tab (display only).
            --ratio F      Split ratio (launch + grid-add). Default: 0.5.
            -h, --help     Show this help.

          Requires: herdr, jq, setsid.
          EOF
          }

          # ---------- shared state ----------
          STATE_DIR="''${XDG_RUNTIME_DIR:-/tmp}/herdr-tui-''${USER:-agent}"
          mkdir -p "$STATE_DIR"

          # ---------- option parsing helpers ----------
          # Populated by parse_common_opts.
          IDLE_SEC=60
          WATCH_CMD=""
          HARD_TIMEOUT=""
          KEEP=0
          LABEL=""
          RATIO="0.5"

          parse_common_opts() {
            while [[ $# -gt 0 ]]; do
              case "$1" in
                --auto-close-on-idle) IDLE_SEC="$2"; shift 2 ;;
                --auto-close-when)    WATCH_CMD="$2"; shift 2 ;;
                --auto-close-timeout) HARD_TIMEOUT="$2"; shift 2 ;;
                --keep)               KEEP=1; shift ;;
                --label)              LABEL="$2"; shift 2 ;;
                --ratio)              RATIO="$2"; shift 2 ;;
                --) shift; REMAINING=("$@"); return 0 ;;
                -h|--help) usage; exit 0 ;;
                -*) echo "herdr-tui: unknown flag: $1" >&2; exit 2 ;;
                *)  REMAINING=("$@"); return 0 ;;
              esac
            done
            REMAINING=()
          }

          # ---------- pane bootstrap ----------
          # Sends <cmd> into pane <id> via sh -c, so aliases don't hijack.
          #
          # The base64 dance lets us pass arbitrary quotes/newlines through
          # `herdr pane run` (which types the string into the pane shell)
          # without escaping. It MUST NOT be shaped as a pipeline: TUIs
          # (glab ci view, k9s, stu, lazygit, ...) require a TTY on stdin,
          # and the last stage of a pipeline inherits the pipe fd instead.
          # So we decode inside a command substitution and exec sh -c
          # foreground, which inherits the pane's controlling PTY.
          run_in_pane() {
            local pane="$1"; shift
            local cmd="$*"
            local b64
            b64=$(printf '%s' "$cmd" | base64 -w0)
            herdr pane run "$pane" \
              "exec sh -c \"\$(printf '%s' $b64 | base64 -d)\"" \
              >/dev/null
          }

          # ---------- auto-close daemon ----------
          # Spawned into the background; watches pane state + optional predicate
          # and closes the pane when conditions match. Detaches from the parent
          # via setsid so the caller returns immediately.
          spawn_auto_close() {
            local pane="$1"
            local idle="$2"
            local watch="$3"
            local hard="$4"

            local script="$STATE_DIR/auto-close-$pane.sh"
            cat >"$script" <<EOF_INNER
          #!${pkgs.bash}/bin/bash
          set -u
          PANE="$pane"
          IDLE=$idle
          WATCH=$(printf '%q' "$watch")
          HARD=$hard
          START=\$(date +%s)
          IDLE_SINCE=\$(date +%s)
          POLL_WATCH=0

          while :; do
            NOW=\$(date +%s)

            if [[ -n "\$HARD" && \$(( NOW - START )) -ge \$HARD ]]; then
              break
            fi

            if ! STATE=\$(herdr pane get "\$PANE" 2>/dev/null); then
              # Pane already gone — user closed it manually.
              exit 0
            fi

            FOCUSED=\$(printf '%s' "\$STATE" | jq -r '.result.pane.focused // false')
            OFFSET=\$(printf '%s' "\$STATE" | jq -r '.result.pane.scroll.offset_from_bottom // 0')

            if [[ "\$FOCUSED" == "true" || "\$OFFSET" != "0" ]]; then
              IDLE_SINCE=\$NOW
            elif [[ \$(( NOW - IDLE_SINCE )) -ge \$IDLE ]]; then
              break
            fi

            if [[ -n "\$WATCH" ]]; then
              POLL_WATCH=\$(( POLL_WATCH + 1 ))
              if (( POLL_WATCH % 5 == 0 )); then
                if sh -c "\$WATCH" >/dev/null 2>&1; then
                  break
                fi
              fi
            fi

            sleep 1
          done

          herdr pane close "\$PANE" >/dev/null 2>&1 || true
          rm -f "$script"
          EOF_INNER
            chmod +x "$script"
            setsid --fork "$script" </dev/null >/dev/null 2>&1
          }

          apply_label() {
            local pane="$1"
            if [[ -n "$LABEL" ]]; then
              herdr pane rename "$pane" "$LABEL" >/dev/null 2>&1 || true
            fi
          }

          maybe_arm_auto_close() {
            local pane="$1"
            if [[ "$KEEP" == "1" ]]; then
              return 0
            fi
            spawn_auto_close "$pane" "$IDLE_SEC" "$WATCH_CMD" "''${HARD_TIMEOUT:-}"
          }

          # ---------- subcommand: launch ----------
          cmd_launch() {
            REMAINING=()
            parse_common_opts "$@"
            if [[ ''${#REMAINING[@]} -eq 0 ]]; then
              echo "herdr-tui launch: no command specified" >&2
              exit 2
            fi

            local split_json pane
            local -a anchor
            if [[ -n "''${HERDR_PANE_ID:-}" ]]; then
              anchor=(--pane "$HERDR_PANE_ID")
            else
              anchor=(--current)
            fi
            if ! split_json=$(herdr pane split "''${anchor[@]}" --direction right --ratio "$RATIO" --no-focus \
                  --env "HERDR_AI_SPLIT=1" \
                  --env "HERDR_AI_ROLE=tui" \
                  --env "HERDR_AI_PARENT_PANE=''${HERDR_PANE_ID:-unknown}" \
                  2>&1); then
              echo "herdr-tui: failed to split pane: $split_json" >&2
              exit 4
            fi
            if ! pane=$(printf '%s\n' "$split_json" | jq -er '.result.pane.pane_id'); then
              echo "herdr-tui: could not parse pane id from: $split_json" >&2
              exit 4
            fi

            apply_label "$pane"
            # Fall back to an ownership label when the caller didn't set --label,
            # so `herdr pane list` still attributes the pane to this agent.
            if [[ -z "$LABEL" ]]; then
              herdr pane rename "$pane" "ai-tui:''${HERDR_PANE_ID:-?}" >/dev/null 2>&1 || true
            fi
            run_in_pane "$pane" "''${REMAINING[*]}"
            maybe_arm_auto_close "$pane"
            printf '%s\n' "$pane"
          }

          # ---------- subcommand: grid-open ----------
          cmd_grid_open() {
            local label="tui-grid"
            while [[ $# -gt 0 ]]; do
              case "$1" in
                --label) label="$2"; shift 2 ;;
                -h|--help) usage; exit 0 ;;
                *) echo "herdr-tui grid-open: unknown arg: $1" >&2; exit 2 ;;
              esac
            done

            local tab_json tab_id pane_id
            if ! tab_json=$(herdr tab create --label "$label" --no-focus 2>&1); then
              echo "herdr-tui: failed to create tab: $tab_json" >&2
              exit 4
            fi
            tab_id=$(printf '%s\n' "$tab_json" | jq -er '.result.tab.tab_id')
            pane_id=$(printf '%s\n' "$tab_json" | jq -er '.result.root_pane.pane_id')

            # Best-effort ownership label on the tab's root pane. The tab
            # itself isn't spawnable with --env, so downstream grid-add
            # panes carry the HERDR_AI_* env instead.
            herdr pane rename "$pane_id" "ai-tui:''${HERDR_PANE_ID:-?}:root" >/dev/null 2>&1 || true

            # Grid state: initial pane not yet used, next split direction = right.
            local state="$STATE_DIR/grid-$tab_id.state"
            cat >"$state" <<EOF
          panes=0
          last_pane=$pane_id
          next_dir=right
          EOF
            printf '%s\n' "$tab_id"
          }

          # ---------- subcommand: grid-add ----------
          cmd_grid_add() {
            if [[ $# -eq 0 ]]; then
              echo "herdr-tui grid-add: missing <grid-id>" >&2
              exit 2
            fi
            local grid_id="$1"; shift
            local state="$STATE_DIR/grid-$grid_id.state"
            if [[ ! -f "$state" ]]; then
              echo "herdr-tui grid-add: unknown grid $grid_id (state file missing)" >&2
              exit 3
            fi

            REMAINING=()
            parse_common_opts "$@"
            if [[ ''${#REMAINING[@]} -eq 0 ]]; then
              echo "herdr-tui grid-add: no command specified" >&2
              exit 2
            fi

            # shellcheck disable=SC1090
            source "$state"
            # panes / last_pane / next_dir are defined by the sourced state file above.
            # shellcheck disable=SC2154
            local pane
            # shellcheck disable=SC2154
            if [[ "$panes" == "0" ]]; then
              # First TUI reuses the tab's initial pane. That pane was
              # created by `herdr tab create`, so its shell doesn't have
              # HERDR_AI_SPLIT baked in — the TUI still runs there fine,
              # only the shell prompt marker is missing on this one pane.
              pane="$last_pane"
            else
              local split_json
              if ! split_json=$(herdr pane split "$last_pane" --direction "$next_dir" --ratio "$RATIO" --no-focus \
                    --env "HERDR_AI_SPLIT=1" \
                    --env "HERDR_AI_ROLE=tui-grid" \
                    --env "HERDR_AI_PARENT_PANE=''${HERDR_PANE_ID:-unknown}" \
                    2>&1); then
                echo "herdr-tui: failed to split $last_pane: $split_json" >&2
                exit 4
              fi
              if ! pane=$(printf '%s\n' "$split_json" | jq -er '.result.pane.pane_id'); then
                echo "herdr-tui: could not parse pane id from: $split_json" >&2
                exit 4
              fi
            fi

            apply_label "$pane"
            if [[ -z "$LABEL" ]]; then
              herdr pane rename "$pane" "ai-tui:''${HERDR_PANE_ID:-?}:$panes" >/dev/null 2>&1 || true
            fi
            run_in_pane "$pane" "''${REMAINING[*]}"
            maybe_arm_auto_close "$pane"

            local new_dir
            if [[ "$next_dir" == "right" ]]; then new_dir="down"; else new_dir="right"; fi
            cat >"$state" <<EOF
          panes=$(( panes + 1 ))
          last_pane=$pane
          next_dir=$new_dir
          EOF
            printf '%s\n' "$pane"
          }

          # ---------- subcommand: grid-close ----------
          cmd_grid_close() {
            if [[ $# -eq 0 ]]; then
              echo "herdr-tui grid-close: missing <grid-id>" >&2
              exit 2
            fi
            local grid_id="$1"
            herdr tab close "$grid_id" >/dev/null 2>&1 || true
            rm -f "$STATE_DIR/grid-$grid_id.state"
          }

          # ---------- dispatch ----------
          if [[ $# -eq 0 ]]; then usage; exit 2; fi
          sub="$1"; shift
          case "$sub" in
            launch)     cmd_launch "$@" ;;
            grid-open)  cmd_grid_open "$@" ;;
            grid-add)   cmd_grid_add "$@" ;;
            grid-close) cmd_grid_close "$@" ;;
            -h|--help)  usage ;;
            *) echo "herdr-tui: unknown subcommand: $sub" >&2; usage; exit 2 ;;
          esac
        '';
      };
    in
    {
      home.packages = [ herdr-tui ];

      # Pre-allow the herdr-tui wrapper so Claude doesn't re-prompt.
      home.file.".claude/settings.d/21-herdr-tui.json".text = builtins.toJSON {
        permissions.allow = [
          "Bash(herdr-tui:*)"
        ];
      };
    };
}
