---
name: "SW: Ticket"
description: "Boot or resume a support-ticket workflow instance under statewright"
allowed-tools: Bash(bd:*), Bash(try:*), Bash(dust:*), Bash(herdr:*), Bash(jq:*), Bash(cat:*), Bash(mkdir:*), Bash(test:*), Bash(date:*), Bash(ls:*), mcp__statewright__*
category: "Workflow"
tags: ["statewright", "workflow", "support-ticket"]
---

Boot or resume the `support-ticket` statewright workflow for a Jira ticket.
Enforces one instance per ticket, seeds a persistent try-dir + Dust
conversation + root bead, then hands control to the `statewright-gateway`
MCP so all further tool calls are gated by the workflow's per-state
`allowed_tools`.

**Input**: The argument after `/sw:ticket` is the ticket ID (e.g. `PLAT-4012`).
If missing, refuse — do NOT prompt: this command must be scriptable.

**Ticket ID contract**: `^[A-Z][A-Z0-9]+-[0-9]+$`. Reject anything else with
exit-style error and stop.

---

## Steps

**1. Validate and set variables**

```bash
ticket="$1"
[ -n "$ticket" ] || { echo "usage: /sw:ticket <TICKET-ID>" >&2; exit 2; }
printf '%s' "$ticket" | grep -Eq '^[A-Z][A-Z0-9]+-[0-9]+$' \
  || { echo "ERROR: '$ticket' is not a valid ticket ID (want ABC-1234)" >&2; exit 2; }

instance="support-ticket--$ticket"
instance_dir="$HOME/.cache/claude/statewright/$instance"
metadata="$instance_dir/metadata.json"
```

**2. Enforce the tab-claim invariant**

If `HERDR_TAB_ID` is set, the tab's label MUST equal `$ticket`. Mismatch
means the operator is running this command from the wrong pane and any
`bd claim` would land in the wrong ticket context. First invocation
without any herdr tab is allowed — the tab will be spawned in step 4.

```bash
if [ -n "$HERDR_TAB_ID" ]; then
  current_label=$(herdr tab get "$HERDR_TAB_ID" --json 2>/dev/null | jq -r '.label // empty')
  [ -z "$current_label" ] && current_label=$(herdr tab get "$HERDR_TAB_ID" 2>/dev/null \
    | grep -oE '\b[A-Z][A-Z0-9]+-[0-9]+\b' | head -1)
  if [ -n "$current_label" ] && [ "$current_label" != "$ticket" ]; then
    echo "ERROR: tab labelled '$current_label' but ticket is '$ticket'." >&2
    echo "  One-tab-per-ticket is enforced." >&2
    echo "  Find the existing tab:  herdr tab list | grep -F '$ticket'" >&2
    echo "  Focus it:               herdr tab focus <tab-id>" >&2
    exit 2
  fi
fi
```

**3. Resume path — if the instance already exists**

```bash
if [ -f "$metadata" ]; then
  echo "Resuming $instance (already exists at $instance_dir)"
  cat "$metadata" | jq .
  # Refuse to create a parallel instance. Read events.jsonl tail to show state.
  test -s "$instance_dir/events.jsonl" \
    && tail -5 "$instance_dir/events.jsonl" | jq -c 'select(.event or .type)'
  # Hand off to the workflow — statewright_get_status establishes current state
  # for the agent's next actions.
  # (Agent proceeds with mcp__statewright__statewright_get_status …)
  exit 0
fi
```

Refuse to fork: do NOT create a second instance for the same ticket. If
the operator wants a clean-slate rerun, they `rm -rf "$instance_dir"`
first.

**4. New-instance path — seed try-dir, Dust conversation, root bead, tab**

```bash
mkdir -p "$instance_dir"

# 4a. Try-dir (idempotent — try creates $date-$slug format; find or create).
try_dir=$(ls -td "$HOME/src/tries"/*"-$ticket" 2>/dev/null | head -1)
if [ -z "$try_dir" ]; then
  try_dir="$HOME/src/tries/$(date +%Y-%m-%d)-$ticket"
  mkdir -p "$try_dir"
fi

# 4b. Dust conversation — reuse if the try-dir already has one recorded, else seed.
if [ -f "$try_dir/dust-conversation-id" ]; then
  dust_conversation_id=$(cat "$try_dir/dust-conversation-id")
else
  # Seed with a minimal opener; capture the conversation id from --json output.
  dust_conversation_id=$(dust chat --new --json --agent orchestrator \
    -- "Starting support ticket workflow for $ticket." \
    | jq -r .conversationId)
  printf '%s' "$dust_conversation_id" > "$try_dir/dust-conversation-id"
fi

# 4c. Root bead — one per ticket, labelled ticket:<id>.
root_bead=$(bd q "$ticket — support ticket" \
  --labels "ticket:$ticket,phase:root" --priority 1)

# 4d. herdr tab — spawn labelled tab if not already inside one.
if [ -z "$HERDR_TAB_ID" ]; then
  herdr tab create --label "$ticket" --cwd "$try_dir" --focus 2>/dev/null || true
fi
```

**5. Write `metadata.json`**

```bash
created_at=$(date -Iseconds)
jq -n \
  --arg ticket "$ticket" \
  --arg root_bead "$root_bead" \
  --arg try_dir "$try_dir" \
  --arg dust_conversation_id "$dust_conversation_id" \
  --arg workflow "support-ticket" \
  --arg created_at "$created_at" \
  '{ticket:$ticket, root_bead:$root_bead, try_dir:$try_dir,
    dust_conversation_id:$dust_conversation_id,
    workflow:$workflow, created_at:$created_at}' \
  > "$metadata"
cat "$metadata"
```

**6. Boot the workflow via the statewright MCP tool**

Call `mcp__statewright__statewright_load_workflow` with
`{"workflow": "support-ticket"}`. The gateway loads
`~/.claude/workflows/support-ticket.json` and enters state `discover`.

Then continue as the agent in `discover`, respecting the state's
`allowed_tools`. The persistence wrapper (task 7.1) records every
subsequent tool decision + transition to `$instance_dir/events.jsonl`.

The first agent action inside `discover` should be to write an
`instance_created` line into `$instance_dir/events.jsonl` if the
persistence wrapper is not yet active (task 7.1) — otherwise the
wrapper handles it. Emit shape:
`{"seq": 0, "ts": "<created_at>", "event": "instance_created", "ticket": "$ticket", "root_bead": "$root_bead"}`.

---

## Refuse

Stop and error (non-zero exit, terse message to stderr) when:

- **No ticket argument** — this command is not interactive.
- **Ticket ID does not match `^[A-Z][A-Z0-9]+-[0-9]+$`**.
- **Herdr tab label mismatches the ticket** — do not silently rebind.
- **An instance directory already exists but `metadata.json` is missing** —
  a prior run partially wrote state. Ask the operator to inspect
  `$instance_dir` and delete or repair before rerunning.
- **A root bead with label `ticket:<id>` already exists but has a
  different id than what a fresh `bd q` would create** — the operator
  should intervene rather than let the workflow hold a stale bead id.

## See also

- `/home/juliendauliac/ghq/github.com/Dauliac/dotfiles/openspec/changes/statewright-workflow-layer/specs/agent-workflows/support-ticket/spec.md` — the requirements this command satisfies (`/sw:ticket` boot, metadata contract, single-instance).
- `/home/juliendauliac/ghq/github.com/Dauliac/dotfiles/workflows/support-ticket.json` — the `MachineDefinition` the gateway loads.
- `/home/juliendauliac/ghq/github.com/Dauliac/dotfiles/docs/statewright/cheatsheet.md` §7 — MCP tool signatures used above.
- `~/.claude/skills/jira-ticket/SKILL.md` — the legacy hardcoded pipeline; superseded by this command for `--via-statewright` runs (see task 5.1).
