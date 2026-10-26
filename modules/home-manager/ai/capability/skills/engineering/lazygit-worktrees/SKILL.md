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

Each spawn deduplicates against `herdr pane list` by matching
`foreground_cwd == <toplevel>` and label prefix `lazygit-`, so re-firing
the same event is a no-op.

Runtime kill-switch (per session): `XI_DISABLE_LAZYGIT_WORKTREES_HOOK=1`.

## Manual recipe

Use this only when the auto-trigger did not fire (e.g. the agent
`cd`ed into a worktree without a `CwdChanged` event, or lazygit was
closed manually and the human wants it back):

```bash
toplevel=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null) || {
  echo "lazygit-worktrees: $PWD is not a git worktree"; exit 0; }

label="lazygit-$(basename "$toplevel")"

# Dedup: pane already open for this toplevel?
if herdr pane list 2>/dev/null \
   | jq -r --arg t "$toplevel" '.result.panes[]?
       | select(.foreground_cwd == $t and (.terminal_title_stripped // "" | startswith("lazygit")))
       | .pane_id' \
   | grep -q .; then
  echo "lazygit already open for $toplevel"
  exit 0
fi

herdr-tui launch \
  --label "$label" \
  --ratio 0.35 \
  --auto-close-on-idle 1800 \
  -- bash -c "cd '$toplevel' && exec lazygit"
```

Notes:

- **Label**: `lazygit-<repo-basename>`. The prefix `lazygit-` is what
  the dedup check greps for.
- **Dedup key**: `foreground_cwd == <toplevel>`. `cwd` alone drifts
  with the shell; `foreground_cwd` tracks the TUI's active dir.
- **Ratio 0.35**: lazygit renders well in a narrow side-panel; keeps
  the agent's pane dominant.
- **30-min idle close**: long enough to walk away, short enough that
  abandoned panes clean up. Do NOT use `--auto-close-when` (no "done"
  predicate for a persistent viewer) or `--keep` (leaks panes across
  long sessions).

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
