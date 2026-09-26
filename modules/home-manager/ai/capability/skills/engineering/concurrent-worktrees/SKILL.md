---
name: concurrent-worktrees
description: Isolate concurrent tracks of work into their own git worktree via `try worktree <branch>` so a second track never lands in the same directory as an in-flight change. Use when (1) spawning parallel subagents that each modify code, (2) a new task arrives while an implementation or investigation still has uncommitted changes, (3) exploring an alternative approach without overwriting the current one, (4) two long-lived commands would fight for a port / test DB / build cache / output file. Triggers on "in parallel", "concurrently", "at the same time", "while X is still running", "branch off", "try an alternative", "spike this without losing", "compare two approaches", "second track". Skip for sequential work (do X then Y), read-only investigation, or a solo branch switch on a clean tree — plain `git switch` suffices there.
---

# concurrent-worktrees — one worktree per parallel track

Before starting a second track of work in this repo, split it into
its own git worktree with `try worktree <branch>`. Each track then
holds its own cwd, its own index, its own dev-server port, its own
build cache — the original checkout keeps its state untouched.

## The command

From inside the repo:

```bash
try worktree <branch-name>
```

Creates `$TRY_PATH/<date>-<slug>/` as a worktree checked out on
`<branch-name>` (created if new). Cd into that dir and work from
there. Full mechanics — picker keys, `TRY_PATH` / `TRY_PROJECTS`,
graduate flow — live in the `try` skill.

## Completion criterion

After the split, both of these hold:

- `git -C <original-checkout> status` shows the first track's tree
  untouched.
- `git -C <worktree-path> rev-parse --show-toplevel` returns the new
  try dir.

If either fails, the split did not take — do not start the second
track yet.

## Detection heuristic

Reach for this **before** the second track starts, not after files
collide. If the current checkout has uncommitted changes, an
in-flight branch, or a running long command (dev server, test watch,
migration), worktree first.

For a fleet of parallel subagents each editing code, spawn one
worktree per subagent and pass the worktree path into the subagent's
prompt. Same-cwd fanout corrupts the shared index and produces
un-reviewable diffs.

## Cleanup

When the track lands (merged / rebased back to the mainline):

```bash
git worktree remove <path>          # run from the original checkout
```

When the track is abandoned:

```bash
git worktree remove --force <path>
```

Then `Ctrl-D` on the try dir inside the `try` picker to garbage-
collect it. Stale worktrees hold ref locks and clutter the next
`try` pick.

## Composes with

- **try**: owns `try worktree` and the `$TRY_PATH` layout — read
  that skill for picker keys and the graduate flow.
- **ghq**: canonical repo location under
  `~/ghq/<host>/<owner>/<repo>` that the worktree is anchored to.
- **herdr-layout** / **herdr-run**: one herdr workspace per
  worktree, long commands launched in panes scoped to the
  worktree's cwd (not the original), so panes and labels travel
  together across sessions.
- **beads**: one bead per track; record the worktree path in
  `bd note` so the split survives the next session's context.
- **hunk**: review each worktree's diff independently before merge.
- **jira-ticket**: already applies this pattern per support ticket
  (per-ticket subdir + symlinked worktree) — reach for that skill
  instead when the second track is a support ticket.
