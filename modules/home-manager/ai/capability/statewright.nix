{
  # Statewright workflow-layer capability. Ships the three upstream binaries
  # onto PATH (packaged in modules/packages/statewright.nix) plus a first-class
  # `statewright approve` operator command — which upstream does NOT provide
  # (see docs/statewright/cheatsheet.md §8.4: statewright's CLI has no
  # `approve` sub-command; approval is only reachable via the MCP tool
  # `statewright_transition` or via the gateway's hook HTTP server).
  #
  # OpenSpec change: statewright-workflow-layer. Requirement:
  #   "Approval interface is a first-class operator command"
  # See openspec/changes/statewright-workflow-layer/specs/agent-workflows/spec.md.
  #
  # WRAPPER NAMING DECISION
  # -----------------------
  # The upstream `statewright` binary is the Ratatui TUI (crates/tui). It owns
  # its own argv namespace (`--task`, `--workdir`, `--tool-mode`, ...) and does
  # NOT dispatch a sub-command called `approve` — appending `approve` to its
  # argv would land inside its own flag parser and fail. So we install the
  # wrapper as its own binary, `statewright-approve`, and document the
  # user-facing invocation as `statewright-approve <instance-id> <event>`.
  # The spec's phrasing "statewright approve <instance-id> <event>" reads as
  # a *conceptual* command; the concrete PATH entry is `statewright-approve`
  # (hyphen), which shells will tab-complete alongside `statewright`.
  #
  # GATEWAY HOOK URL CONTRACT
  # -------------------------
  # The wrapper POSTs to a hook URL discovered at
  #   ~/.cache/claude/statewright/<instance-id>/gateway-hook.url
  # (a single-line file containing the base URL of the gateway's hook HTTP
  # server, e.g. `http://127.0.0.1:37421`). Writing that file is the job of
  # the gateway-launch wrapper in a later task of this OpenSpec change (task
  # 4.x / 7.x); this module does NOT create it. If the file is missing, the
  # wrapper exits non-zero with an actionable error naming the expected path.
  flake.modules.homeManager.ai-capability-statewright =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      statewright-approve = pkgs.writeShellApplication {
        name = "statewright-approve";
        runtimeInputs = [
          pkgs.curl
          pkgs.jq
          pkgs.coreutils
        ];
        text = ''
          # statewright-approve <instance-id> <event>
          #
          # Resolves a pending human-approval gate on a running statewright
          # workflow instance by POSTing to the gateway's hook HTTP server.
          #
          # Contract:
          #   Input:  ~/.cache/claude/statewright/<instance-id>/gateway-hook.url
          #           (single-line base URL of the gateway hook server,
          #            written by the gateway-launch wrapper — task 4.x).
          #   Wire:   POST <hook-url>/approve
          #           Content-Type: application/json
          #           Body: {"instance_id": "<id>", "event": "<event>", "approved": true}
          #   Exit:   0 on 2xx; 1 on 4xx/5xx (response body echoed to stderr);
          #           2 on usage error; 3 on missing hook URL file.
          #
          # See docs/statewright/cheatsheet.md §7.1 (statewright_transition
          # MCP tool — the semantic equivalent invoked by the gateway on our
          # behalf) and §8.4 (why this wrapper exists at all).
          set -euo pipefail

          if [ "$#" -ne 2 ]; then
            printf 'usage: statewright-approve <instance-id> <event>\n' >&2
            exit 2
          fi

          instance_id="$1"
          event="$2"

          cache_root="''${XDG_CACHE_HOME:-$HOME/.cache}/claude/statewright"
          hook_url_file="$cache_root/$instance_id/gateway-hook.url"

          if [ ! -r "$hook_url_file" ]; then
            printf 'statewright-approve: no gateway hook URL for instance %s\n' \
              "$instance_id" >&2
            printf '  expected: %s\n' "$hook_url_file" >&2
            printf '  (written by the gateway-launch wrapper on instance boot)\n' >&2
            exit 3
          fi

          hook_url="$(tr -d '[:space:]' < "$hook_url_file")"
          if [ -z "$hook_url" ]; then
            printf 'statewright-approve: gateway hook URL file is empty: %s\n' \
              "$hook_url_file" >&2
            exit 3
          fi

          body="$(jq -cn \
            --arg id "$instance_id" \
            --arg ev "$event" \
            '{instance_id: $id, event: $ev, approved: true}')"

          tmp_body="$(mktemp)"
          trap 'rm -f "$tmp_body"' EXIT

          http_code="$(curl \
            --silent \
            --show-error \
            --output "$tmp_body" \
            --write-out '%{http_code}' \
            --max-time 15 \
            --request POST \
            --header 'Content-Type: application/json' \
            --data "$body" \
            "$hook_url/approve" || true)"

          case "$http_code" in
            2??)
              exit 0
              ;;
            "")
              printf 'statewright-approve: gateway unreachable at %s\n' \
                "$hook_url" >&2
              exit 1
              ;;
            *)
              printf 'statewright-approve: gateway rejected approval (HTTP %s)\n' \
                "$http_code" >&2
              if [ -s "$tmp_body" ]; then
                cat "$tmp_body" >&2
                printf '\n' >&2
              fi
              exit 1
              ;;
          esac
        '';
      };
      # GATEWAY CONFIG PATH DECISION
      # ----------------------------
      # We drop the gateway config at
      #   ~/.config/statewright/gateway-config.json
      # (XDG_CONFIG_HOME layout). Rationale:
      #   1. The gateway is a standalone MCP server binary, not a Claude
      #      Code artefact — it is invoked *by* Claude Code (via mcpServers
      #      below) but its config belongs under the tool's own XDG namespace,
      #      not `~/.claude/`. This matches how other MCP servers on this box
      #      (codegraph, mcp-nixos, ...) keep their own config outside
      #      `~/.claude/`.
      #   2. Keeps `~/.claude/` reserved for Claude-Code-native artefacts
      #      (skills/, workflows/, settings.d/, commands/) so tearing down
      #      Claude Code does not orphan gateway state, and vice-versa.
      #   3. `statewright-gateway --config <PATH>` accepts an absolute path,
      #      so location is a free choice.
      #
      # GATEWAY CONFIG SHAPE
      # --------------------
      # Per `docs/statewright/cheatsheet.md` §8.1, the on-disk gateway config
      # is `GatewayConfig` — a `workflows: {name -> MachineDefinition}` map
      # plus `default`, `upstream_servers`, `workdir`. The `MachineDefinition`
      # is inlined (not referenced by path), so we import the shipped
      # `workflows/support-ticket.json` at eval time via `builtins.fromJSON`
      # and embed it. The `.claude/workflows/support-ticket.json` file
      # installed below is the *human-editable* copy shipped for IDE tooling
      # and for the docs; the gateway itself reads the inlined copy in
      # gateway-config.json.
      workflowsDir = ../../../../workflows;
      supportTicketDefinition = builtins.fromJSON (
        builtins.readFile "${workflowsDir}/support-ticket.json"
      );
      gatewayConfig = {
        default = "support-ticket";
        workflows = {
          support-ticket = supportTicketDefinition;
        };
        upstream_servers = [ ];
      };
    in
    {
      home.packages = [
        pkgs.statewright-gateway
        pkgs.sw-agent
        pkgs.statewright-tui
        statewright-approve
      ];

      # MCP WIRING DECISION (task 4.1)
      # ------------------------------
      # Register the gateway as an MCP server via the sibling
      # `ai-capability-mcp` module's `programs.claude-code.mcpServers`
      # attrset (see mcp.nix). We use the same aggregation pattern rather
      # than dropping a raw `.claude/settings.d/40-statewright-mcp.json` for
      # two reasons:
      #   1. Consistency — every other MCP server on this box (codegraph,
      #      nixos, anytype, playwright, lsp) is declared via `mcpServers`.
      #      A stray settings.d file would fragment the surface.
      #   2. Merge safety — home-manager's claude-code module owns the
      #      final settings.json; writing a raw settings.d/ file bypasses
      #      that merge and can silently lose entries on rename or precedence
      #      changes upstream.
      programs.claude-code.mcpServers.statewright = {
        type = "stdio";
        command = "statewright-gateway";
        args = [
          "--config"
          "${config.home.homeDirectory}/.config/statewright/gateway-config.json"
          "--hook-server"
        ];
      };

      # Gateway config file — see decision block above.
      home.file.".config/statewright/gateway-config.json".text =
        builtins.toJSON gatewayConfig;

      # Workflow JSONs shipped to `~/.claude/workflows/` for IDE tooling
      # (schema-backed editing) and for skills / docs that reference the
      # canonical workflow file. `source =` (not `text =`) so the file is
      # a store-path symlink — hash-stable, no rebuild on unrelated changes
      # to the module.
      home.file.".claude/workflows/support-ticket.json".source =
        "${workflowsDir}/support-ticket.json";
      home.file.".claude/workflows/support-ticket.schema.json".source =
        "${workflowsDir}/support-ticket.schema.json";

      # Skill card: memory jog for the operator when a workflow parks on an
      # approval gate. Kept terse per the OpenSpec task brief (~20 lines).
      home.file.".claude/skills/statewright-approve/SKILL.md".text = ''
        ---
        name: statewright-approve
        description: Resolve a pending human-approval gate on a running statewright workflow instance. Use when a workflow has parked on a `requires_approval: true` transition (surfaced via `pending_approval` in `statewright_get_state`, or an `approval_gate` line in the instance's `events.jsonl`, or a bead note flagging the instance as blocked on approval). Triggers on "approve the workflow gate", "unblock the statewright instance", "the workflow is waiting on me", "let the transition through", "approve event X on instance Y". Does NOT trigger for MR approvals, Jira transitions, or Datadog deploy gates — those have their own skills. Requires the gateway's hook HTTP server to have written `~/.cache/claude/statewright/<instance-id>/gateway-hook.url` on instance boot; if that file is absent, the workflow was never wired to a running gateway and this skill cannot help.
        ---

        # statewright-approve

        1. Identify the parked instance: `ls ~/.cache/claude/statewright/` or grep
           `events.jsonl` for the most recent `approval_gate` line.
        2. Read the pending event name from the `approval_gate` payload
           (`message` field per cheatsheet §9) or from
           `statewright_get_state`'s `pending_approval.event`.
        3. Run `statewright-approve <instance-id> <event>`.
        4. Verify the transition applied: tail `events.jsonl` for a
           `transition` line with matching `trigger`.

        Exit codes: 0 approved / 1 gateway rejected or unreachable (body on
        stderr) / 2 usage error / 3 hook URL file missing.

        See `docs/statewright/cheatsheet.md` §7.1 (`statewright_transition`),
        §8.4 (why a wrapper is needed), and §9 (`events.jsonl` shape).
      '';
    };
}
