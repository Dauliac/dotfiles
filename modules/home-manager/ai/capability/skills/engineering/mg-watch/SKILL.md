---
name: mg-watch
description: Open `mg` (mardi-gras beads viewer) in a herdr side-panel scoped to the repo whose bead DAG is being driven, so the human sees ready-queue + claims live. One pane per repo, deduped by the `mg-<repo>` pane label. Fires automatically from a `PostToolUse`/Bash hook on any `bd` command plus `SessionStart`, both gated on at least one in-progress bead (see modules/home-manager/ai/workspace/mg-watch.nix); the agent only invokes this skill manually when the auto-trigger did not fire or the panel was closed and the human wants it back. Trigger on "open mg", "mg split", "beads panel", "show me the DAG", or whenever the agent begins driving beads work in a repo with no mg pane.
---

# mg-watch  -  live mardi-gras beads TUI, one per repo

Fires while the agent is driving beads work (`bd ready` / `bd claim` /
bead-DAG loop) in a repo with a `.beads/` directory. `mg` is a
persistent companion viewer the human glances at while the agent
claims and closes beads  -  the pane is a side-panel, not a focused
workspace.

## Auto-trigger (default path)

The `mg-watch` hook spawns the pane on two events (see
`modules/home-manager/ai/workspace/mg-watch.nix`):

- `PostToolUse` on `Bash`, pre-filtered by `if: "Bash(bd *)"`  -  the
  agent having just run `bd` through the Bash tool is the signal that
  a claude is driving beads. Runs `async`, so the probe never sits in
  the agent's critical path.
- `SessionStart`  -  reopens the panel when a resumed session already
  holds a claimed bead.

Both are gated on `bd list --status in_progress` being non-empty.

**Why the event and not the DB**: there is no way to ask beads "is
this bead claimed by a claude". `bd update --claim` writes `assignee`
from git `user.name` (verified: `assignee` is the human's name,
`actor` is null), so an agent claim and a human claim are identical
rows. The agent-ness lives in the *event* that fired the hook, which
is why the Bash trigger is the strong one and `SessionStart` is
explicitly the weaker fallback.

Runtime kill-switch (per session): `XI_DISABLE_MG_WATCH_HOOK=1`.

## Manual recipe

Use this only when the auto-trigger did not fire (e.g. the human
closed the pane and wants it back, or beads work is starting without
any `bd` command having run yet):

```bash
repo=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$PWD")
[ -d "$repo/.beads" ] || { echo "mg-watch: no .beads/ in $repo, skipping"; exit 0; }

label="mg-$(basename "$repo")"

self=$(herdr pane current | jq -r '.result.pane.pane_id')
ws=$(herdr pane current | jq -r '.result.pane.workspace_id')

# Dedup: a pane already carrying this label?
for p in $(herdr pane list --workspace "$ws" \
           | jq -r '.result.panes[] | select(has("agent")|not) | .pane_id'); do
  if [ "$(herdr pane get "$p" | jq -r '.result.pane.label // empty')" = "$label" ]; then
    echo "mg already open for $repo ($p)"
    exit 0
  fi
done

setsid --fork herdr-tui launch \
  --label "$label" \
  --ratio 0.78 \
  --auto-close-on-idle 604800 \
  --auto-close-when "! herdr pane get '$self' >/dev/null 2>&1" \
  -- mg
```

Notes:

- **Label**: `mg-<repo-basename>`. One `mg` pane per repo, always.
- **Dedup key**: the pane `label`, fetched with `herdr pane get`.
  `label` is **not** returned by `herdr pane list`, and the payload
  nests under `.result.panes[]`, not `.panes[]`  -  an earlier version
  of this recipe grepped `herdr pane list | jq '.panes[].label'`,
  which matched nothing and leaked a new split per invocation. Never
  match on `terminal_title` / `terminal_title_stripped` either:
  `herdr-tui launch` wraps every command in
  `exec sh -c "$(printf '%s' <base64> | base64 -d)"`, so the title is
  that wrapper and a `startswith("mg")` test silently never fires.
- **`setsid --fork`**: a hook's process group is torn down when the
  hook returns. A plain `&` + `disown` stays in that group and gets
  killed mid-launch, leaving a blank half-created pane behind.
- **No flush prefix**: mardi-gras 0.36 queries the `bd` CLI live, so
  the pane is current the moment it opens. It only falls back to
  reading `.beads/issues.jsonl` when `bd` is not on PATH. Do not
  re-add a `bd sync --flush-only &&` or `bd export &&` prefix  -  the
  former is not even a valid flag on beads 1.3.x.
- **Ratio 0.78 gives the viewer 22%**: `--ratio` is the share kept by
  the pane being split, so the new side-panel gets `1 - ratio`  -  it
  reads backwards. Kept identical to lazygit-worktrees so an `mg` and
  a `lazygit` panel open together stay symmetric. See that skill for
  the measurement and the compounding caveat. To narrow an
  already-open pane:
  `herdr pane resize --pane <id> --direction right --amount F`.
- **Lifetime tied to the agent pane, not idle**: herdr-tui counts
  "engagement" as pane-focused OR scrolled-up, and a viewer the human
  only glances at is neither, so the old `--auto-close-on-idle 900`
  reaped the panel mid-session. Pin idle effectively-never and let
  `--auto-close-when` close it when the owning Claude pane disappears.
  Do NOT use `--keep`: it skips the watcher entirely, so the pane
  outlives the session.
- **Do not close on "no beads in progress"**: that predicate reaps the
  pane at the exact moment the agent closes the last bead, which is
  when the human most wants to look at it.

## When NOT to reach for this

- No `.beads/` at the git toplevel  -  `mg` has nothing to show.
- No bead in progress: the session is not driving the DAG, so the
  panel is noise. The hook enforces this; honor it manually too.
- An `mg` pane is already open for this repo in the workspace  -  the
  dedup check short-circuits silently.

## Composes with

- **beads**  -  the `bd` CLI itself; `mg-watch` reads what `bd` writes
  by calling it directly, so the viewer tracks the Dolt-backed source
  of truth without an intermediate export step.
- **beads-flow**  -  the "drive the DAG until no ready beads remain"
  loop. Its first `bd ready` fires the hook, so the human sees each
  claim / close land in the viewer without anyone asking.
- **lazygit-worktrees**  -  the sibling hook. Same dedup key, same
  `setsid --fork` spawn, same agent-pane-bound lifetime; read that
  module alongside this one when changing either.
- **tui-context**  -  this is a single-TUI case (one `mg` per repo);
  if a second TUI joins (e.g. `ci-watch` after a push), tui-context
  promotes both to a grid via `grid-open` / `grid-add`.
- **herdr-run**  -  for one-shot bd commands where output matters to
  the human (e.g. a `bd ready` list in a scratch pane). `mg-watch`
  is the persistent side-panel; `herdr-run` is the transient one.
