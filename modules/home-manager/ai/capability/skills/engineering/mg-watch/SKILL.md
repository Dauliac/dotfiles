---
name: mg-watch
description: When starting beads work in a repo with `.beads/`, open `mg` (mardi-gras beads viewer) in a herdr side-panel scoped to this workspace so the human sees ready-queue + DAG live. Auto-closes on 15-min idle. Trigger on `bd ready`, `bd claim`, `beads workflow`, "open mg", "mg split", "side-panel", or any moment the agent begins driving the bead DAG. Deduped by `mg-<repo>` label — never spawns twice per workspace.
---

# mg-watch — live mardi-gras beads TUI, one per repo

Fires when the agent is about to drive beads work (`bd ready` /
`bd claim` / bead-DAG loop) and a `.beads/` directory is present.
`mg` is a passive viewer of `.beads/issues.jsonl`; the split is a
side-panel the human glances at, not a focused pane.

## Single-TUI recipe

```bash
[ -d .beads ] || { echo "mg-watch: no .beads/ in $PWD, skipping"; exit 0; }

if herdr pane list --workspace "$HERDR_WORKSPACE_ID" 2>/dev/null \
   | jq -r '.panes[].label // empty' \
   | grep -q "^mg-"; then
  echo "mg already open in this workspace"
  exit 0
fi

herdr-tui launch \
  --label "mg-$(basename "$PWD")" \
  --auto-close-on-idle 900 \
  -- bash -c 'bd sync --flush-only && mg'
```

Notes:

- **Label**: `mg-<repo-basename>` — the dedup prefix `mg-` is what the
  guard above greps for. One `mg` pane per workspace, always.
- **Flush prefix**: `bd sync --flush-only` refreshes
  `.beads/issues.jsonl` before `mg` reads it. Without this, `mg` shows
  stale state up to the last `bd sync`.
- **15-min idle close**: beads work has no "done" state — the DAG is
  ongoing while the agent runs. 900 s is long enough to walk away for
  coffee, short enough that abandoned panes clean up. Do NOT use
  `--auto-close-when` (no predicate makes sense) or `--keep` (leaks
  panes across long sessions).
- **No `.beads/` bail-out**: `mg` is useless without a JSONL export
  to read; the guard short-circuits cleanly.

## When NOT to reach for this

`mg` is a passive viewer — if the current session is not doing beads
work (pure grep, docs read, one-shot bash), do not open it.

## Composes with

- **beads** — the `bd` CLI itself; `mg-watch` reads what `bd` writes
  (via the JSONL export). The `bd sync --flush-only` prefix keeps
  the viewer in sync with the Dolt-backed source of truth.
- **beads-flow** — the "drive the DAG until no ready beads remain"
  loop. Fire `mg-watch` at loop entry so the human sees each claim /
  close land in the viewer.
- **tui-context** — this is a single-TUI case (one `mg` per repo);
  if a second TUI joins (e.g. `ci-watch` after a push), tui-context
  promotes both to a grid via `grid-open` / `grid-add`.
- **herdr-run** — for one-shot bd commands where output matters to
  the human (e.g. `bd ready` list in a scratch pane). `mg-watch`
  is the persistent side-panel; `herdr-run` is the transient one.
