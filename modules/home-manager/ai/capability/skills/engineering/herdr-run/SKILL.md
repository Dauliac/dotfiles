---
name: herdr-run
description: USE herdr-run for every build, test, check, lint, format, deploy, migration, install, provisioning, push, --watch, or long-running command — anything from the repo/system lifecycle where the output would matter to a human in a terminal. The user watches the pane live; the captured output still returns to me the same way a normal Bash tool call would, so I do not go blind. Also trigger on the user saying "run", "run and show me", "watch this", "tail this", "show me the output", "in a split", "in a pane", "let me watch". Prefer plain Bash only when the command is a pure short read whose output only feeds my next reasoning step — small queries, single-file cat/head/tail, narrow grep/rg, existence checks (which, test -f), git status/log/diff that fits a screen, jq extraction I'm about to parse, pwd/whoami/date. Rule of thumb: would a human sit and watch this in a terminal? Split it. Is it inner-monologue plumbing? Don't. Bonus sweet spot: interactive prompts (sudo, y/N, git rebase -i, read) work great in the split because the user can type in the pane directly.
---

# herdr-run — visible command execution in a herdr split pane

`herdr-run` splits the current herdr pane, runs a command in the new one,
waits for it to finish, and returns the captured output on stdout — so
you can consume it the same way you consume a normal Bash tool call, while
the user still gets a live pane to watch.

## Deciding: split, or plain Bash?

There is no whitelist of command names. Reason about the command in
front of you against three axes and choose from that:

1. **Duration.** Will this take more than a couple seconds? If yes, the
   user has time to look at it — lean split. Fast, blocking, sub-second
   commands are inner-monologue plumbing — lean Bash.
2. **Mutation vs. read.** Does the command change state the user cares
   about (writes files, ships builds, deploys, migrates, pushes,
   installs, provisions)? Users almost always want to see mutations
   happen — split. Pure reads that only inform your next step — Bash.
3. **Human interest in the output.** If a human at a terminal would
   sit and watch this — build progress, test failures, deploy diff,
   provisioning steps, download bars — it's split-worthy. If the output
   is a short piece of data you're about to parse or thread into your
   next reasoning step — Bash.

Two out of three "yes" → split. Two out of three "no" → Bash. All three
mixed → err on the side of splitting; the user can always ignore the
pane, and it auto-closes on idle.

## Explicit user cues override

If the user says *"run <cmd>"*, *"run and show me"*, *"show me the
output"*, *"let me watch"*, *"tail this"*, *"in a pane"*, *"in a
split"*, *"keep it visible"*, or any close variant, use herdr-run
regardless of what the three-axis reasoning suggests. They're telling
you they want the pane.

## Interactive TTY commands — a sweet spot, not an exclusion

Commands that prompt for input (`sudo <cmd>`, `y/N` confirmations,
`git rebase -i`, `git commit` without `-m`, `read -r`, `nix shell` REPL,
a `,` picker) are actually a *great* fit for herdr-run: the split pane
has a real TTY, so the user can type the password / confirmation /
edit directly in the pane while you sit back. You get the captured
output once they finish responding. Bonus UX: the user reviews the
command's behavior live while it runs, then you catch the transcript.

Two things to keep in mind for interactive runs:

- **Timeout headroom.** herdr-run's default `--timeout` is 5 minutes.
  If the user might be slow to respond (looking up a password, reading
  the diff before confirming), bump it: `herdr-run --timeout 900000 …`
  (15 min). The pane itself sticks around regardless — the timeout is
  only about how long you wait for the completion marker before giving
  up.
- **Pagers still misbehave.** A pager (`less`, `bat` without
  `--paging=never`) parks the shell waiting for `q` without printing
  the completion marker. Bypass the alias (`command cat …`, `\cat …`),
  or disable paging (`PAGER=cat …`). If you actually want the human to
  page, use `--spawn` so you don't wait — they can page at leisure.

## The one true hard exclusion

- **Commands whose output you must parse structurally in the next
  step.** Bash gives you the raw buffer without shell prompt echoes or
  the BEGIN/END markers herdr-run wraps around; if you're about to feed
  the output to `jq`, a regex, or your own reasoning as data — Bash.

## Core invocations

| Intent | Command |
|---|---|
| Run in the persistent pane, capture output | `herdr-run <cmd>` |
| Fire-and-forget (dev server, watch) | `herdr-run --spawn <cmd>` |
| Separate persistent pane for a different concern | `herdr-run --role dev-server <cmd>` |
| Longer timeout for interactive prompts | `herdr-run --timeout 900000 <cmd>` |
| Vertical split on first creation | `herdr-run --direction down <cmd>` |
| Don't echo captured output back | `herdr-run --quiet <cmd>` |
| Force use of a specific pane | `herdr-run --pane <id> <cmd>` |
| Forget the persistent-pane state (next call splits fresh) | `herdr-run --forget` |

## How the persistent pane works

There is one persistent pane per `(HERDR_PANE_ID, role)` inside a
herdr pane, falling back to `(cwd, role)` outside one. Created on
the first `herdr-run` call (split off the caller's pane), then reused
for every subsequent call from the same agent. Never closed by
`herdr-run` — the pane belongs to the human and stays open across
sessions.

- State file: `$XDG_RUNTIME_DIR/herdr-run/pane-<sha1(pane_id|role)>.id`
  (or `sha1(cwd|role)` when `$HERDR_PANE_ID` is unset).
- Reuse path: read state → `herdr pane get` to verify alive → reuse.
- Fresh-split path: no state or the recorded pane is gone → split
  and re-record.

Every spawned pane inherits three env vars: `HERDR_AI_SPLIT=1`,
`HERDR_AI_ROLE=<role>`, `HERDR_AI_PARENT_PANE=<owning HERDR_PANE_ID>`.
Zsh renders a `[🤖 AI · <role> ← <parent>]` marker line above the
prompt in these panes. The pane itself is labeled `ai:<role>:<parent>`
so `herdr pane list` attributes it back to the owning agent.

**Multi-agent implication:** two Claude sessions in the same repo
each get their own persistent pane — they never share. This is the
correctness reason the state key includes `$HERDR_PANE_ID`.

Use `--role` to keep separate long-lived panes for concerns that
shouldn't clobber each other (e.g. `--role dev-server` for `npm run
dev` alongside default for one-off tests). `--forget` clears the state
file so the next call splits a new pane; the old pane stays open.

Since the pane persists, you never block on an idle-close: as soon as
the command's END marker fires, `herdr-run` returns to you with the
captured output. Typical overhead: <500ms on top of the command
itself.

## Composes with

- **herdr-layout**: when you need control over the *shape* of the
  split (new tab instead of a split, promote to a new workspace, name
  the pane), reach for the CRUD primitives directly and then
  `herdr-run --pane <id> <cmd>` into the pane you shaped.
- **herdr-find**: before spawning a fresh pane for a role, check
  whether a matching pane already exists (by cwd + terminal title)
  and reuse it with `herdr-run --pane <id> <cmd>`.
- **hunk**: `herdr-run --spawn --role diff-review hunk diff --watch`
  gives the user a live diff review pane (its own persistent role so
  it doesn't share with regular runs) while you continue editing.
- **beads**: run `bd ready` or `bd show <id>` in a pane the user can scan
  while you plan the next move.
- **codegraph**: send `codegraph explore "<question>"` to a pane so the
  raw structural context is visible without dumping it into the chat.

## Behind the scenes (so you can debug)

Two shell tools cooperate:

- **`herdr-run`** (client, what you invoke) — resolves the persistent
  pane (state file lookup or fresh split), base64-encodes your command,
  and types this into the pane:
  ```
  ia-run <marker> <base64_cmd>
  ```
  Then waits for `herdr pane wait-output --regex '■ ia-run [<marker>] exit'`
  and extracts the output between BEGIN and END markers via `awk`.

- **`ia-run`** (pane-side helper, runs inside the pane) — prints the
  colored/bold markers around the command's own output:
  ```
  ▶ ia-run [4f7a2b] $ cargo build
     …command's own output…
  ■ ia-run [4f7a2b] exit 0 (took 12s)
  ```
  Executes via `sh -c` so the pane's TTY is preserved for sudo,
  `y/N`, `git rebase -i`, `read -r`, `nix shell`.

The pane display stays clean — one short line typed in per call, then
pretty markers around the output. Human can scroll back through the
transcript across many `herdr-run` invocations and see each command's
start/end/exit code at a glance.

If `herdr-run` or `ia-run` isn't on PATH, home-manager hasn't been
rebuilt yet — user needs to run their `xi home switch`.
