---
name: herdr-layout
description: Shape the herdr terminal workspace — create, rename, move, resize, close panes, tabs, workspaces, and Git worktrees over the socket API. Trigger on "open a split", "split this pane", "new tab", "open a tab", "rename this tab", "close the tab", "focus the other tab", "move this pane to a new tab", "swap panes", "resize this split", "zoom this pane", "new workspace", "rename workspace", "close workspace", "focus workspace <name>", "make a worktree for <branch>", "open the worktree", "remove the worktree". For "run a command in a split and capture output" use the `herdr-run` skill instead — this skill is about the *shape* of the workspace, not command execution. For "which panes/tabs/workspaces exist right now" or "find the pane that…" use the `herdr-find` skill.
---

# herdr-layout — reshape the workspace

Every layout mutation is a socket-API subcommand. Signatures below are
from the running server (`herdr <noun> <verb>` with no args prints
usage). All list/discovery lives in `herdr-find`; command execution
inside a new pane lives in `herdr-run`.

## Panes

```bash
# Split (creates a new pane; returns metadata as JSON)
herdr pane split [<pane_id>|--pane ID|--current] \
    --direction right|down \
    [--ratio FLOAT] [--cwd PATH] [--env KEY=VALUE] \
    [--right-click herdr|pane] [--focus|--no-focus]

# Rename / clear label
herdr pane rename <pane_id> <label>
herdr pane rename <pane_id> --clear

# Focus a neighbor from the current pane
herdr pane focus --direction left|right|up|down [--pane ID|--current]

# Move a pane elsewhere in the layout
herdr pane move <pane_id> --tab <tab_id> --split right|down \
    [--target-pane ID] [--ratio FLOAT] [--focus|--no-focus]
herdr pane move <pane_id> --new-tab       [--workspace ID] [--label TEXT]
herdr pane move <pane_id> --new-workspace [--label TEXT] [--tab-label TEXT]

# Swap / resize / zoom / close
herdr pane swap  <pane_id_a> <pane_id_b>
herdr pane resize <pane_id> --ratio FLOAT      # 0.0–1.0 of parent split
herdr pane zoom  [<pane_id>|--current] [--on|--off|--toggle]
herdr pane close [<pane_id>|--current]
```

## Tabs

```bash
herdr tab create   [--workspace ID] [--label TEXT] [--focus|--no-focus]
herdr tab rename   <tab_id> <label>
herdr tab focus    <tab_id>
herdr tab close    <tab_id>
herdr tab get      <tab_id>            # JSON metadata
```

## Workspaces ("spaces")

```bash
herdr workspace create   [--label TEXT] [--focus|--no-focus]
herdr workspace rename   <workspace_id> <label>
herdr workspace focus    <workspace_id>
herdr workspace close    <workspace_id>
herdr workspace get      <workspace_id>
```

## Worktrees (Git-backed workspaces)

```bash
herdr worktree create --repo PATH --branch NAME [--label TEXT] [--focus]
herdr worktree open   <worktree_id_or_path>     [--focus|--no-focus]
herdr worktree remove <worktree_id>             [--force]
```

A worktree wraps `git worktree add` and lands in its own workspace —
use this instead of `git worktree add` + `herdr workspace create`
manually. Removal defers to `git worktree remove`; pass `--force` when
the worktree has local changes you're intentionally discarding.

## Recipes

**Split-and-name for a persistent role**:

```bash
new=$(herdr pane split --current --direction right --json | jq -r .pane_id)
herdr pane rename "$new" "test-watch"
```

**Fresh tab in the current workspace, labeled**:

```bash
tab=$(herdr tab create --label "review" --json | jq -r .tab.tab_id)
```

**Promote a busy pane to its own tab** so a long build has the whole
tab, without killing the pane's history:

```bash
herdr pane move <pane_id> --new-tab --label "build"
```

**Promote a pane to its own workspace** — same idea, one level up
(great for a support ticket you want to isolate):

```bash
herdr pane move <pane_id> --new-workspace \
    --label "PLAT-4030" --tab-label "explore"
```

**Worktree for a branch review**:

```bash
herdr worktree create --repo "$PWD" --branch review/feat-x --focus
# … poke around … then:
herdr worktree remove <worktree_id>
```

## Gotchas

- **Pane / tab / workspace IDs are ephemeral** — capture from JSON
  output of the mutating call, don't hard-code across sessions.
  Use `herdr-find` to look them up fresh when needed.
- **`--current` sentinel** — many pane commands accept `--current` in
  place of a `<pane_id>`, resolving to the invoking pane. Use it when
  the caller *is* the pane you mean. **Inside an agent-owned shell
  prefer `--pane "$HERDR_PANE_ID"`** — deterministic, immune to focus
  races and to the caller's shell drifting off the intended pane. The
  agent's own pane id is injected by herdr at spawn time.
- **`--env KEY=VALUE` on `pane split`** — inherited by the new pane's
  shell. `herdr-run` and `herdr-tui` use this to tag AI-owned splits
  with `HERDR_AI_SPLIT` / `HERDR_AI_ROLE` / `HERDR_AI_PARENT_PANE`;
  reach for the same primitive when writing custom split scripts that
  need self-attributing panes.
- **`--focus` / `--no-focus`** — the default varies per command
  (`split` focuses, `move` doesn't); pass explicitly when scripting to
  avoid stealing the user's focus mid-work.
- **`pane move --new-workspace`** creates the workspace with a single
  tab holding the moved pane — you can't retro-add existing tabs to
  a new workspace in one call; move tab-by-tab.
- **`pane close` on the last pane of a tab** closes the tab; on the
  last tab of a workspace, closes the workspace. Cascade is silent —
  check `herdr-find` after if unsure.
- **Worktrees are Git objects** — `worktree remove` without `--force`
  refuses when the checkout has uncommitted changes; that's a
  feature, not a bug. Commit / stash first.

## Composes with

- **herdr-run** — run a command inside a pane you just created.
  Typical: `herdr pane split` + `herdr pane send-keys` is what
  `herdr-run` wraps; use `herdr-run` unless you specifically need
  layout control over the split.
- **herdr-find** — discover the IDs to feed into `rename` / `move` /
  `close`.
- **tui-context** — spawns TUIs at the right shape (single vertical
  split vs. grid tab). Uses `herdr-layout` primitives under the hood.
- **ci-watch / k8s-watch / s3-watch** — domain composers built on
  `tui-context`.
