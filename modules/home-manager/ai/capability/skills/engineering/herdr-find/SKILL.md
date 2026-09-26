---
name: herdr-find
description: Search and inspect the herdr workspace — list panes, tabs, workspaces, worktrees, agents, and filter by name/label/cwd/pid/status via `--json` + jq. Trigger on "which tabs are open", "list my workspaces", "find the pane running X", "which pane is in <cwd>", "what agents are alive", "search my panes for <title>", "which workspace holds <tab>", "show me the pane in the current tab", "where is that agent", "what's in workspace <name>", "which panes are working / idle / done / blocked". For creating, renaming, or moving panes/tabs/workspaces use the `herdr-layout` skill instead — this skill is read-only discovery. For running a command in a pane, use `herdr-run`.
---

# herdr-find — locate things in the herdr workspace

Every list command supports `--json`. Pipe through `jq` to filter by
label, cwd, pid, agent state, or terminal title. All layout mutations
live in `herdr-layout`; this skill is strictly read-only.

## The universal shape

```bash
herdr <noun> list --json | jq '<filter>'
herdr <noun> get  <id> --json          # metadata for one
```

Nouns: `pane`, `tab`, `workspace`, `worktree`, `session`, `agent`.

## Common filters

The JSON returned by `herdr pane list --json` looks like (elided):

```json
{
  "result": {
    "type": "pane_list",
    "panes": [
      {
        "pane_id": "w1G:p22",
        "tab_id": "w1G:t1",
        "workspace_id": "w1G",
        "cwd": "/home/…/dotfiles",
        "foreground_cwd": "/home/…/dotfiles",
        "focused": false,
        "agent": "claude",
        "agent_status": "idle",
        "terminal_title_stripped": "Check twg installation status"
      }
    ]
  }
}
```

Same shape scales to tabs (`tab_id`, `label`, `workspace_id`,
`pane_count`, `focused`) and workspaces (`workspace_id`, `label`,
`focused`, `tab_ids`).

**Find panes running something (by terminal title):**

```bash
herdr pane list --json \
  | jq -r '.result.panes[] | select(.terminal_title_stripped | test("build"; "i")) | .pane_id'
```

**Panes in a given cwd (foreground process, not just shell)**:

```bash
herdr pane list --json \
  | jq -r --arg cwd "$PWD" '.result.panes[] | select(.foreground_cwd == $cwd) | .pane_id'
```

**All agents that are working / blocked (so you know what NOT to
interrupt):**

```bash
herdr pane list --json \
  | jq -r '.result.panes[] | select(.agent_status=="working" or .agent_status=="blocked")
           | "\(.pane_id) \(.agent_status) — \(.terminal_title_stripped)"'
```

**Every tab in a given workspace:**

```bash
herdr tab list --json \
  | jq -r --arg ws w1G '.result.tabs[] | select(.workspace_id == $ws)
           | "\(.tab_id) \(.label)  (\(.pane_count) panes)"'
```

**Which workspace is currently focused:**

```bash
herdr workspace list --json | jq -r '.result.workspaces[] | select(.focused) | .workspace_id'
```

**Panes that this agent spawned** (via `herdr-run` / `herdr-tui`):

```bash
herdr pane list --json \
  | jq -r --arg p "$HERDR_PANE_ID" \
      '.result.panes[]
       | select(.terminal_title_stripped | test("^(ai|ai-tui):.*:" + $p))
       | .pane_id'
```

The ownership label format is `ai:<role>:<parent-pane>` (from
`herdr-run`) or `ai-tui:<parent-pane>[:idx]` (from `herdr-tui`). Every
such pane also carries `HERDR_AI_SPLIT=1` + `HERDR_AI_ROLE` +
`HERDR_AI_PARENT_PANE` in its shell env — useful to grep with
`ps -o pid= -p <shell-pid>` + `/proc/<pid>/environ` when the label was
manually cleared.

**What's the current pane** (for scripts that need to address "here"):

```bash
herdr pane current --json | jq -r '.result.pane.pane_id'
```

## Reading pane output without opening a pager

```bash
herdr pane read <pane_id> [--lines N] [--from-bottom N]
```

Prints the pane's scrollback as text. Great for grepping what a
long-running command produced without focusing the pane or hijacking
the user's TTY.

## Agents

`herdr agent list` and `herdr agent get <target>` return the
agent-lifecycle view — separate from pane discovery, useful when the
question is "who's the claude in that pane" rather than "what's
in that pane". Pair with `herdr agent explain <target>` to see *why*
herdr thinks an agent is `idle` / `working` / `blocked` / `done`.

## Sessions and worktrees

```bash
herdr session  list --json                   # persistent named sessions
herdr worktree list --json                   # git-worktree workspaces
```

Session list is scoped to *this* server; remote sessions need
`herdr --remote <target> session list`.

## Gotchas

- **`cwd` vs `foreground_cwd`** — `cwd` is where the shell was
  spawned; `foreground_cwd` follows `cd` inside the pane. Filter on
  `foreground_cwd` when the question is "which pane is *currently*
  in dir X".
- **`terminal_title_stripped` beats `terminal_title`** — the raw
  title carries an animated status glyph (`✳`, `⠐`, `⠂`) that shifts
  every frame; the stripped form is stable for regex matching.
- **Pane IDs like `w1G:p22`** encode `<workspace>:<pane>`. You can
  read the workspace of a pane straight from the ID without a second
  call, but `workspace_id` in the JSON is the authoritative source.
- **`agent_status` = `unknown`** means either no agent is attached
  or herdr hasn't detected one yet — filter it out when hunting for
  "live agents".
- **`--json` is the only stable format** — the human table is for
  humans; column widths and coloring change. Never parse it.

## Composes with

- **herdr-layout** — feed a discovered ID straight into `rename`,
  `move`, `close`, or `focus` to reshape the workspace.
- **herdr-run** — before spawning a fresh pane for a role, check with
  `herdr-find` whether a matching pane already exists (by cwd + title)
  and reuse it via `herdr-run --pane <id>`.
- **beads** — record long-lived pane IDs / workspace IDs in a bead
  when they anchor a multi-session workflow (support ticket, running
  investigation) so future sessions can `bd show` and re-find them.
