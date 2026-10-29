---
name: lazygit-worktrees
description: Open `lazygit` in a herdr side-panel scoped to each git worktree you are actively working in  -  the main checkout plus any nested worktree (e.g. a `try worktree` branch-off or an agent isolation worktree under `.claude/`). One pane per worktree path, deduped by `foreground_cwd`. Fires automatically from `SessionStart`, `WorktreeCreate`, and `CwdChanged` hooks (see modules/home-manager/ai/workspace/lazygit-worktrees.nix); the agent only invokes this skill manually when the auto-trigger did not fire or an extra worktree needs its own pane. Trigger on "open lazygit", "lazygit split", "watch the diff", "see the staged changes", "git panel", or whenever the agent enters a worktree that currently has no lazygit pane.
---

# lazygit-worktrees  -  one lazygit pane per active git worktree

Fires when the agent is working in a git worktree and no lazygit pane
is scoped to its toplevel yet. `lazygit` is a persistent companion
viewer the human glances at while the agent edits  -  the pane is a
side-panel, not a focused workspace.

## Auto-trigger (default path)

The `lazygit-worktrees` hook spawns one pane per worktree on three
events (see `modules/home-manager/ai/workspace/lazygit-worktrees.nix`):

- `SessionStart`  -  cwd is a git repo → spawn one for its toplevel.
- `WorktreeCreate`  -  a new git worktree was just added via herdr →
  spawn one for its path.
- `CwdChanged`  -  the agent moved into a different worktree (e.g. a
  nested `.claude/` isolation worktree) → spawn one for the new path.

Each spawn deduplicates by the herdr pane **`label`** (`lazygit-<repo>`)
within the current workspace, so re-firing the same event is a no-op.
`label` is only returned by `herdr pane get`, never by `herdr pane list`.

Runtime kill-switch (per session): `XI_DISABLE_LAZYGIT_WORKTREES_HOOK=1`.

## Manual recipe

Use this only when the auto-trigger did not fire (e.g. the agent
`cd`ed into a worktree without a `CwdChanged` event, or lazygit was
closed manually and the human wants it back):

```bash
toplevel=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null) || {
  echo "lazygit-worktrees: $PWD is not a git worktree"; exit 0; }

label="lazygit-$(basename "$toplevel")"

self=$(herdr pane current | jq -r '.result.pane.pane_id')
ws=$(herdr pane current | jq -r '.result.pane.workspace_id')

# Dedup: a pane already carrying this label?
for p in $(herdr pane list --workspace "$ws" \
           | jq -r '.result.panes[] | select(has("agent")|not) | .pane_id'); do
  if [ "$(herdr pane get "$p" | jq -r '.result.pane.label // empty')" = "$label" ]; then
    echo "lazygit already open for $toplevel ($p)"
    exit 0
  fi
done

setsid --fork herdr-tui launch \
  --label "$label" \
  --ratio 0.78 \
  --auto-close-on-idle 604800 \
  --auto-close-when "! herdr pane get '$self' >/dev/null 2>&1" \
  -- lazygit -p "$toplevel"
```

Notes:

- **Label**: `lazygit-<repo-basename>`. The prefix `lazygit-` is what
  the dedup check greps for.
- **Dedup key**: the pane `label`, fetched with `herdr pane get`.
  Never match on `terminal_title` / `terminal_title_stripped`:
  `herdr-tui launch` always runs the command through an
  `exec sh -c "$(printf '%s' <base64> | base64 -d)"` wrapper, so the
  title is that wrapper and a `startswith("lazygit")` test silently
  never fires  -  which leaks one new split per event.
- **`setsid --fork`**: the hook's process group is torn down when the
  hook returns. A plain `&` + `disown` stays in that group and gets
  killed mid-launch, leaving a blank half-created pane behind.
- **Ratio 0.78 gives the viewer 22%**: `--ratio` is the share kept by
  the pane being split, so the NEW side-panel gets `1 - ratio`. This
  reads backwards and the previous value proved it: `0.35` was
  commented as "keeps the agent's pane dominant" while actually
  handing the viewer 65% of the row. Verified empirically  -  a split
  at `0.78` of an 80-column parent produced an 18-column new pane
  (`herdr pane resize --pane <id> --direction right --amount 0`
  prints the live layout with every split ratio, which is how to
  re-check this).
  Ratios compound through nesting: the share is of the PARENT split,
  not of the display, so a viewer inside two nested splits ends up
  narrower than 22% of the screen. Measured on a 186-column tab,
  0.78 yields a 41-column viewer. lazygit falls back to a narrow
  layout (`ScreenMode`) at small widths; the breakpoint is not
  documented and is not recoverable from the binary, so if the
  panel looks cramped widen it with `herdr pane resize` and read
  the ratio off the layout dump instead of guessing a threshold.
  To narrow a pane that is already open:
  `herdr pane resize --pane <id> --direction right --amount F`.
- **Lifetime tied to the agent pane, not idle**: herdr-tui counts
  "engagement" as pane-focused OR scrolled-up, and a viewer the human
  only glances at is neither  -  an idle close would reap it
  mid-session. Pin idle effectively-never and let
  `--auto-close-when` close it when the owning Claude pane disappears.
  Do NOT use `--keep`: it skips the watcher entirely, so the pane
  outlives the session.

## When NOT to reach for this

- Current cwd is not a git worktree (`rev-parse --show-toplevel` fails).
- A lazygit pane is already open for this toplevel in the workspace  - 
  the dedup check short-circuits silently.
- Pure read-only sessions where no diff is being produced (docs
  browse, one-shot grep): the pane adds no value.

## Composes with

- **tui-context**  -  one TUI per worktree. If two worktrees are active
  concurrently, this skill will open two separate lazygit panes, one
  per worktree path, rather than a grid. The one-vs-many layout rule
  applies per-worktree, not globally.
- **concurrent-worktrees**  -  fires `try worktree <branch>` → the
  resulting `WorktreeCreate` event triggers a fresh lazygit for the
  new path.
- **mg-watch**  -  same dedup pattern (`<prefix>-<basename>` label,
  idle-close, bail if the backing dir is absent).
- **herdr-layout**  -  the primitives underneath (`pane split`,
  `pane list`); reach for it when the one-pane-per-worktree default
  needs reshaping.
