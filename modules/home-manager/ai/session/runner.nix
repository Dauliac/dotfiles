{
  # Ships two shell tools that together give Claude a "visible command
  # execution" workflow inside a herdr pane:
  #
  #   ia-run     — pane-side helper. Takes <marker_id> <base64_cmd>,
  #                prints colored/bold BEGIN and END marker lines around
  #                the command, executes it via `sh -c` so the pane's
  #                TTY is preserved for sudo/y-N/read/rebase-i.
  #                On PATH so the pane's shell can invoke it.
  #
  #   herdr-run  — client. Resolves or creates a persistent per-cwd
  #                pane (state file under $XDG_RUNTIME_DIR), types
  #                `ia-run <marker> <b64>` into it, waits for the END
  #                marker via `herdr pane wait-output`, extracts the
  #                command's own output from the buffer, and returns
  #                immediately. Never closes the pane — that's a UX
  #                concern for the human, not the caller.
  #
  # Companion skill: capability/skills/herdr-run/SKILL.md.
  flake.modules.homeManager.ai-session-runner =
    { pkgs, ... }:
    let
      ia-run = pkgs.writeShellApplication {
        name = "ia-run";
        runtimeInputs = with pkgs; [
          coreutils
          gnused
        ];
        text = builtins.readFile ./ia-run/ia-run.sh;
      };

      herdr-run = pkgs.writeShellApplication {
        name = "herdr-run";
        runtimeInputs = with pkgs; [
          herdr
          jq
          coreutils
          gawk
        ];
        text = ''
          # herdr-run — dispatch a command to the persistent Claude-assigned
          # pane for this cwd, wait for it to finish (via ia-run's END
          # marker), and return the captured output. The pane is created
          # once per (cwd, role) and reused across invocations; it is
          # never closed by this tool.

          usage() {
            cat >&2 <<'EOF'
          Usage: herdr-run [OPTIONS] <command...>

          Run <command> in the persistent Claude-assigned herdr pane for
          this cwd (created on first call, reused thereafter). Prints the
          captured output on stdout; the pane stays open for the human.

          Options:
            --role <name>      Which persistent pane to use (default: default).
                               Use different roles to keep separate long-lived
                               panes: --role dev-server, --role tests, etc.
            --direction <d>    Split direction on FIRST creation: right (default) | down.
            --ratio <f>        Split ratio on FIRST creation (default 0.5).
            --pane <id>        Force use of a specific pane (bypasses state file).
            --spawn            Fire-and-forget: dispatch and return immediately
                               without waiting for the command to finish. Prints
                               the pane id on stdout. Ideal for dev servers.
            --timeout <ms>     Wait-output timeout (default 300000 = 5 min).
                               Bump for interactive commands the user may take
                               time to respond to (sudo, git rebase -i).
            --quiet            Don't print captured output on stdout.
            --forget           Delete the persistent-pane state for the current
                               cwd/role so the next call starts fresh. Does NOT
                               close the pane.
            -h, --help         Show this help.

          Requires: herdr, jq, awk, ia-run (on PATH in the pane's shell).
          EOF
          }

          ROLE="default"
          DIRECTION="right"
          RATIO="0.5"
          PANE=""
          SPAWN=0
          TIMEOUT_MS=300000
          QUIET=0
          FORGET=0

          while [[ $# -gt 0 ]]; do
            case "$1" in
              --role)      ROLE="$2"; shift 2 ;;
              --direction) DIRECTION="$2"; shift 2 ;;
              --ratio)     RATIO="$2"; shift 2 ;;
              --pane)      PANE="$2"; shift 2 ;;
              --spawn)     SPAWN=1; shift ;;
              --timeout)   TIMEOUT_MS="$2"; shift 2 ;;
              --quiet)     QUIET=1; shift ;;
              --forget)    FORGET=1; shift ;;
              -h|--help)   usage; exit 0 ;;
              --)          shift; break ;;
              -*)          echo "herdr-run: unknown flag: $1" >&2; exit 2 ;;
              *)           break ;;
            esac
          done

          state_file() {
            local base="''${XDG_RUNTIME_DIR:-/tmp}/herdr-run"
            # Scope state to the owning agent's pane so concurrent Claude
            # sessions in the same repo don't share (and clobber) each
            # other's persistent pane. Falls back to $PWD outside herdr.
            local key="''${HERDR_PANE_ID:-$PWD}"
            local hash
            hash=$(printf '%s|%s' "$key" "$ROLE" | sha1sum | cut -c1-16)
            mkdir -p "$base"
            printf '%s/pane-%s.id' "$base" "$hash"
          }

          if [[ "$FORGET" == "1" ]]; then
            rm -f "$(state_file)"
            echo "herdr-run: forgot persistent pane for cwd=$PWD role=$ROLE" >&2
            exit 0
          fi

          if [[ $# -eq 0 ]]; then
            echo "herdr-run: no command specified" >&2
            usage
            exit 2
          fi

          CMD="$*"

          # Resolve the persistent pane: reuse an existing one for
          # (cwd, role) if it's still alive, otherwise split and record.
          if [[ -z "$PANE" ]]; then
            STATE=$(state_file)
            if [[ -f "$STATE" ]]; then
              candidate=$(cat "$STATE" 2>/dev/null || true)
              if [[ -n "$candidate" ]] && herdr pane get "$candidate" >/dev/null 2>&1; then
                PANE="$candidate"
              fi
            fi
            if [[ -z "$PANE" ]]; then
              # Anchor on the owning agent's pane when running inside
              # herdr; fall back to --current for out-of-herdr callers.
              if [[ -n "''${HERDR_PANE_ID:-}" ]]; then
                anchor=(--pane "$HERDR_PANE_ID")
              else
                anchor=(--current)
              fi
              if ! SPLIT_JSON=$(herdr pane split "''${anchor[@]}" --direction "$DIRECTION" --ratio "$RATIO" --no-focus \
                    --env "HERDR_AI_SPLIT=1" \
                    --env "HERDR_AI_ROLE=$ROLE" \
                    --env "HERDR_AI_PARENT_PANE=''${HERDR_PANE_ID:-unknown}" \
                    2>&1); then
                echo "herdr-run: failed to split pane: $SPLIT_JSON" >&2
                exit 4
              fi
              if ! PANE=$(printf '%s\n' "$SPLIT_JSON" | jq -er '.result.pane.pane_id'); then
                echo "herdr-run: could not parse new pane id from: $SPLIT_JSON" >&2
                exit 4
              fi
              # Human-legible ownership label so `herdr pane list`
              # shows who spawned each split. Best-effort.
              herdr pane rename "$PANE" "ai:$ROLE:''${HERDR_PANE_ID:-?}" >/dev/null 2>&1 || true
              printf '%s' "$PANE" > "$STATE"
            fi
          fi

          # Fresh 8-char marker per call so consecutive runs never collide.
          MARKER=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')
          CMD_B64=$(printf '%s' "$CMD" | base64 -w0)

          # Type a clean single-line invocation into the pane. `ia-run`
          # lives on PATH via home-manager; it prints the pretty markers
          # and execs the decoded command via `sh -c`.
          if ! herdr pane run "$PANE" "ia-run $MARKER $CMD_B64" >/dev/null; then
            echo "herdr-run: failed to send command to pane $PANE" >&2
            exit 5
          fi

          if [[ "$SPAWN" == "1" ]]; then
            printf '%s\n' "$PANE"
            exit 0
          fi

          # ia-run's END marker: `■ ia-run [<marker>] exit <rc> (took Ns)`.
          # Match the unique substring; the ANSI-decorated prefix on the
          # line means we can't rely on ^ line-start against the raw buffer.
          if ! herdr pane wait-output "$PANE" \
                --regex "■ ia-run \[$MARKER\] exit" \
                --timeout "$TIMEOUT_MS" >/dev/null; then
            echo "herdr-run: timed out after ''${TIMEOUT_MS}ms waiting for completion marker" >&2
            exit 124
          fi

          if [[ "$QUIET" == "0" ]]; then
            # Read with `--format ansi` so the captured command output
            # keeps its colors. ia-run's markers are ANSI-decorated too,
            # so we can't line-anchor on `^▶`/`^■` — use substring match
            # on the unique 8-hex marker instead. Strip terminal-buffer
            # trailing \r for clean stdout.
            herdr pane read "$PANE" --source recent-unwrapped --format ansi \
              | awk -v m="$MARKER" '
                  index($0, "▶ ia-run [" m "]") { on=1; next }
                  index($0, "■ ia-run [" m "]") { on=0; exit }
                  on { sub(/\r$/, ""); print }
                '
          fi
        '';
      };
    in
    {
      home.packages = [ ia-run herdr-run ];

      # Pre-allow both binaries so Claude doesn't re-prompt for every
      # invocation. `ia-run` will also be run by the pane's shell after
      # herdr-run types it in, but it's not called from Claude directly.
      home.file.".claude/settings.d/20-herdr-run.json".text = builtins.toJSON {
        permissions.allow = [
          "Bash(herdr-run:*)"
          "Bash(ia-run:*)"
        ];
      };
    };
}
