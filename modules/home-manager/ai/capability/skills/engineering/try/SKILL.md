---
name: try
description: Ephemeral workspace manager — create date-prefixed scratch directories under `$TRY_PATH` (default `~/src/tries`), clone repos into them, create git worktrees inside them, graduate a good one into a real project. Trigger on "spike this", "throwaway workspace", "clone this into a try dir", "worktree for X", or any short-horizon investigation that shouldn't pollute a permanent project location. This is the `try` CLI (v1.10.x by tobi/…), not the shell builtin verb.
---

# try — ephemeral workspace manager

`try` creates and picks date-prefixed workspaces under `$TRY_PATH`
(default `~/src/tries`). Each workspace is a scratch directory the
user can graduate into a real project (`Ctrl-G` in the picker) or
throw away (`Ctrl-D`).

## When to reach for it

- Any investigation that needs its own directory but doesn't deserve
  a permanent home yet — spikes, ticket reproductions, dependency
  bisects, one-off scripts.
- Cloning a repo just to poke at it: `try clone <url>` puts it in
  a dated try dir instead of the current cwd.
- A git worktree from the current repo for a branch you'll throw
  away after: `try worktree <name>`.
- Support / on-call ticket work — see the `jira-ticket` skill for the
  full flow that stacks per-ticket subdirs under a day-support parent.

Do NOT use `try` for long-lived work — that's what `ghq` + real
project dirs are for. Graduate the good ones with `Ctrl-G`.

## Layout convention

```
$TRY_PATH/                              (default: ~/src/tries)
├── 2026-09-08-support/                 (day / topic scope)
│   ├── PLAT-4012/                      (ticket-id subdir)
│   │   ├── .dust/conversation-id       (dust convo, one per ticket)
│   │   ├── proof.md                    (jira-explore output)
│   │   ├── fix.md                      (jira-fix output)
│   │   ├── answer.md                   (jira-answer output — STE100)
│   │   └── repo -> ../../../ghq/…/repo/../worktrees/plat-4012  (symlink)
│   └── PLAT-4013/…
└── 2026-09-09-support/…
```

The date-prefixed dir gets created automatically by `try` when the
picker's "Create new" is used. For scripting, create it directly:

```bash
support_root="$TRY_PATH/$(date +%F)-support"
ticket_dir="$support_root/<TICKET-ID>"
mkdir -p "$ticket_dir/.dust"
```

## Core commands

| Intent | Command |
|---|---|
| Interactive picker (or create) | `try [query]` |
| Clone repo into dated try dir  | `try clone <url> [name]` |
| Worktree from current git repo | `try worktree <branch-name>` |
| Non-interactive shell script   | `try exec [query]` → source the output |
| Emit shell init function       | `try init [path]` |
| Show help                      | `try --help` |

`try` accepts PR / MR URLs too — `try https://github.com/…/pull/123`
clones the repo and checks out the PR branch.

## Shell init (one-time)

```bash
# ~/.zshrc or ~/.bashrc
eval "$(try init ~/src/tries)"
```

Without the init, `try` prints navigation script to stdout instead of
`cd`-ing — for scripts use `eval "$(try exec <query>)"`.

## Keybindings inside the picker

| Key | Action |
|---|---|
| ↑ / ↓, Ctrl-P / Ctrl-N | Navigate |
| Enter                  | Select / create |
| Ctrl-R                 | Rename |
| Ctrl-G                 | Graduate to `$TRY_PROJECTS` (real project) |
| Ctrl-D                 | Mark for deletion |
| Ctrl-T                 | Create new try |
| Esc                    | Cancel |

## Environment

- `TRY_PATH` — tries directory (default `~/src/tries`).
- `TRY_PROJECTS` — graduation destination (default parent of `TRY_PATH`).

## Recipes

**Support ticket setup** (see `jira-ticket` for the full flow):

```bash
support="$HOME/src/tries/$(date +%F)-support"
mkdir -p "$support/<TICKET-ID>/.dust"
cd "$support/<TICKET-ID>"
```

**Clone-then-worktree, symlink into the try dir**:

```bash
ghq get -p github.com/<owner>/<repo>
repo=$(ghq list -p -e <owner>/<repo>)
git -C "$repo" worktree add "$repo/../worktrees/<branch>" <branch>
ln -s "$repo/../worktrees/<branch>" "$ticket_dir/repo"
```

**Graduate a good try to a real project**: run `try`, arrow to the
dir, `Ctrl-G` — moves it to `$TRY_PROJECTS/<name>`.

## Gotchas

- Without `eval "$(try init …)"` in the shell, `try` cannot `cd` —
  it prints a script instead. Use `try exec` in scripts.
- The interactive picker is a full TUI — do not call it inside a
  scripted / non-interactive context; use `try clone`, `try worktree`,
  or `mkdir -p "$TRY_PATH/…"` directly.
- The dated dir is the workspace's date of creation, not the ticket's
  date — the naming is `YYYY-MM-DD-<slug>`.
- `TRY_PATH` empty in a subshell (as in this session's env) — set it
  explicitly before scripting: `TRY_PATH="${TRY_PATH:-$HOME/src/tries}"`.

## Composes with

- **jira-ticket / jira-explore / jira-fix / jira-answer**: the try
  dir is the durable per-ticket workspace those workflows write to.
- **ghq**: clone repos into their canonical `~/ghq/…` path, worktree
  from there, symlink the worktree into the try dir.
- **herdr-run** / **tui-context**: open panes scoped to the try dir
  so the user sees ticket-local investigation live.
- **herdr-layout**: create a `herdr workspace` per try dir, labeled
  after the try dir name, so the whole investigation lives in one
  visual container that survives across sessions.
- **herdr-find**: locate the try-dir workspace/panes by label or
  cwd (`foreground_cwd` == the try path) before spawning duplicates.
