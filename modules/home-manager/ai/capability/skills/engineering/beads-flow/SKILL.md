---
name: beads-flow
description: Drive execution over an existing bead DAG — `bd ready` picks the next unblocked bead, claim it, dispatch to the matching skill (by `phase:<name>` label), do the work, `bd note` reasoning, `bd close` on success or `bd note`-with-error + re-queue on failure. Loops until no ready beads remain OR the next ready bead is `blocking:human`. Trigger on "work through the beads", "next task", "drive the DAG", "pick up where we left off", "resume", "continue the effort", "keep going", "bd ready loop". Never advances past a `blocking:human` bead without operator input.
---

# beads-flow — the ready→claim→work→close loop

The runtime side of the beads pattern. Given a DAG built by
`beads-decompose`, drive it: pick the next unblocked bead, dispatch
to a phase-specific skill, close on success.

## When to reach for it

- Resuming a support ticket / refactor / incident across sessions —
  "where were we, what's next?"
- After a phase skill (`jira-explore`, `jira-fix`, …) closes its
  bead — loop to the next.
- Operator says "keep going" / "next" / "drive the effort".

Do NOT reach for it for one-shot work — that's what direct execution
is for.

## Prerequisites

- Read `beads` (base surface) and `beads-decompose` (how the DAG got
  built).
- The DAG's root bead ID (or a stable label like `ticket:PLAT-4012`)
  so `bd ready --labels …` can scope the loop.

## The loop

```bash
scope_label="ticket:PLAT-4012"   # or whatever the DAG's root label is

# 0. Preflight for ticket:* scoped loops — enforce one-tab-per-ticket.
#    See jira-ticket "Tab-claim invariant". The tab label is the
#    pipeline's source of truth for which ticket this shell owns;
#    a mismatch means work would land in the wrong operator context.
case "$scope_label" in
  ticket:*)
    ticket="${scope_label#ticket:}"
    if [ -z "$HERDR_TAB_ID" ]; then
      echo "ERROR: beads-flow on $scope_label must run inside a herdr pane." >&2
      echo "  Start herdr and switch to (or spawn) the '$ticket' tab, then re-run." >&2
      echo "  Discover:  herdr tab list | grep -F '$ticket'" >&2
      echo "  Spawn:     herdr tab create --label $ticket --cwd \$ticket_dir --focus" >&2
      exit 2
    fi
    current_tab_label=$(herdr tab get "$HERDR_TAB_ID" --json 2>/dev/null \
      | jq -r '.label // empty')
    # Fall back to the human table if --json isn't supported by this build.
    [ -z "$current_tab_label" ] && current_tab_label=$(herdr tab get "$HERDR_TAB_ID" 2>/dev/null \
      | grep -oE '\b[A-Z][A-Z0-9]+-[0-9]+\b' | head -1)
    if [ "$current_tab_label" != "$ticket" ]; then
      echo "ERROR: tab $HERDR_TAB_ID is labelled '$current_tab_label' but scope is '$ticket'." >&2
      echo "  One-tab-per-ticket is enforced. Do NOT re-run jira-ticket setup — that" >&2
      echo "  would create a second tab. Find and focus the existing tab:" >&2
      echo "    herdr tab list | grep -F '$ticket'" >&2
      echo "    herdr tab focus <tab-id>" >&2
      exit 2
    fi
    ;;
esac

while :; do
  # 1. Pick the next ready bead in scope
  next=$(bd ready --labels "$scope_label" --json 2>/dev/null \
    | jq -r '.[0].id // empty')
  if [ -z "$next" ]; then
    echo "No ready beads in scope $scope_label — DAG complete or fully blocked."
    break
  fi

  # 2. Inspect it — refuse to auto-run if it wants a human
  info=$(bd show "$next" --json)
  title=$(printf '%s' "$info" | jq -r .title)
  labels=$(printf '%s' "$info" | jq -r '.labels | join(",")')

  case ",$labels," in
    *,blocking:human,*)
      echo "Next: $next — $title"
      echo "Labels: $labels — needs operator input. Pausing loop."
      exit 0
      ;;
  esac

  # 3. Dispatch by phase label — the routing table (below) maps
  #    phase:<name> → skill to invoke.
  phase=$(printf '%s' "$labels" | tr , '\n' | grep '^phase:' | head -1 | cut -d: -f2)
  echo "Working: $next [$phase] $title"

  # 4. Claim, work, close
  bd update "$next" --claim
  bd note "$next" "Started at $(date -Iseconds) via beads-flow."

  # <invoke the matching skill for $phase — see routing table>
  # e.g. phase=explore → run the jira-explore recipe against $ticket
  #      phase=review  → run jira-review
  # If the skill returns non-zero, log + park:
  if ! dispatch_phase "$phase" "$next"; then
    bd note "$next" "FAILED at $(date -Iseconds). Not closing. Operator to intervene."
    echo "Bead $next failed — stopping loop for operator input."
    exit 1
  fi

  bd note "$next" "Closed at $(date -Iseconds)."
  bd close "$next"
done
```

## Phase → skill routing (support ticket template)

| Phase label | Skill to invoke | Notes |
| --- | --- | --- |
| `phase:set-capability` | `jira-pick` step 5, or `twg jira workitem update --field 'Platform Capability=...'` directly | Independent — often auto-close if already set |
| `phase:explore`        | `jira-explore` | Writes `proof.md`; close when proof green |
| `phase:fix-design`     | `jira-fix` steps 1-5 | Writes `fix.md`; requires user OK before close |
| `phase:implement`      | `jira-fix` step 6 + `glab-mr-open` | Emits MR URL + IID |
| `phase:ci-green`       | `glab-mr-ready` pipeline probe | Polls until terminal state |
| `phase:review`         | `jira-review` | Loops on comments; close on approvals green |
| `phase:merge`          | `jira-merge` | Requires ci-green + review approvals |
| `phase:tag`            | `jira-merge` tag step | Skip-close if repo not tag-managed |
| `phase:deploy` + `env:<env>` | `jira-deploy` per env | Manual gate on `env:prod` |
| `phase:verify` + `env:<env>` | `jira-monitor` per env | pup + kubectl + aws menu |
| `phase:answer`         | `jira-answer` | Draft; requires user OK before posting |
| `phase:close`          | `jira-answer` posting step | Posts + transitions Done |
| `phase:watch-related-mr` | `ci-watch` foreground + `async-wait` background — the MR URL is written into the bead as `watch:mr=<iid>` so wake-back reconstructs via async-wait recipe 4b | Filed by `beads-decompose` from `related-mrs.txt` (produced by `jiraai-review --deep`). Always `blocking:human` — operator opts in per MR |

## Human-gate contract

A bead labelled `blocking:human` means: **do NOT auto-claim, do NOT
auto-run**. Print the title + context + suggested command; wait for
operator instruction. Typical uses:
- `env:prod` deploy — always manual, even if verify-staging is green
- Any bead whose fix design was not yet user-OK'd
- A retry after a red pipeline — operator decides retry vs abort

## Long-running phases — arm async-wait, don't block

Some phases have a natural "wait for external state" tail
(`phase:ci-green` = wait for pipeline; `phase:deploy env:*` = wait
for deploy job; `phase:verify env:*` = wait for baseline
stabilization; `phase:watch-related-mr` = wait for another team's
MR to land). Do NOT block the flow-loop on these — arm
**async-wait** with the appropriate primitive and the `watch:` bead
tag, then continue the loop (other beads may be ready in parallel).

Convention: whenever a dispatched skill returns "waiting — armed
async-wait", the flow-loop leaves the bead in-progress with the
async-wait note, moves on to the next `bd ready` (typically ends
the loop if the DAG's other lanes are also waiting). On wake, the
async-wait wake-prompt re-enters `beads-flow drive --labels
ticket:<KEY>` — the bead's state is fresh, the next dispatch is
naturally chosen.

## Failure protocol

When a dispatched skill returns non-zero:

1. **Do NOT close the bead** — it stays in-progress with the failure
   captured as a `bd note`.
2. **Do NOT auto-retry** — one failure per skill invocation; the
   operator picks retry vs pivot.
3. **Break the loop** — subsequent ready beads may depend on this
   one's success; a silent skip poisons the DAG.
4. **Log verbatim**: exit code, last 20 lines of stderr, and any
   artifact paths the skill wrote.

## Rate + safety

- No parallel dispatch by default — one bead at a time keeps the
  loop legible and avoids race with the `blocking:human` gate.
- Explicit `--parallel N` flag can fan out independent sub-beads
  (e.g., `verify-dev` sub-tasks pup + kubectl + aws in parallel).
- `--dry-run` mode: print the routing table + next-N beads without
  claiming or invoking anything — useful for "show me the plan".

## Composes with

- **beads / beads-decompose** — the base + planning primitives.
- **jira-ticket** — the orchestrator that calls this loop after
  `beads-decompose` at setup.
- **jira-explore / jira-fix / jira-review / jira-merge / jira-deploy
  / jira-monitor / jira-answer** — the phase skills dispatched by
  the routing table.
- **glab-mr-open / glab-mr-ready / glab-mr-assign** — used by the
  implement / ci-green / review phases respectively.
- **herdr-layout** — when the DAG spans multiple in-flight beads
  (parallel phases, watch-related-mr, awaiting-reporter), give each
  active bead its own tab labeled `bd-<id>` via `herdr tab create
  --label "bd-$id"` so the operator sees at a glance which beads are
  live.
- **herdr-find** — before dispatching a bead, check if a tab already
  exists for it (`herdr tab list --json | jq --arg lbl "bd-$id"
  '.result.tabs[] | select(.label==$lbl)'`) and focus it instead of
  spawning a duplicate.
