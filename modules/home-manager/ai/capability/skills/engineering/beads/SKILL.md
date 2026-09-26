---
name: beads
description: Use the beads (`bd`) CLI as durable, dependency-aware memory for coding work — issue tracking, DAG dependencies, blocker management, ready-queue picking, cross-session handoff. Trigger when the user asks to find ready work, claim/close tasks, create follow-up work, inspect blockers, recover project context, or when a task is long-horizon, cross-session, has sub-tasks. Triggers on "bd ready", "bd claim", "bd close", "bd create", "bd note", "bd link", "beads", "find ready work", "what's next", "pick up where we left off", "track this", "remember to", "come back to", "park this", "defer this", "follow-up on", "close that ticket", "reopen". Prefer `bd` over TodoWrite / TaskCreate / markdown TODO lists for any task tracking in this repo. Inside a Gas City rig, prefer `gc bd ...` over plain `bd`.
---

# Beads (`bd`) — persistent graph memory for coding agents

`bd` is a distributed graph issue tracker backed by Dolt. Treat it as the
agent's long-term memory: anything worth revisiting across sessions, or any
work with dependencies between steps, belongs in beads.

## When to reach for it

- The user asks to remember, track, park, defer, follow-up, or "come back
  to" something — create a bead.
- A task decomposes into multiple sub-tasks with ordering constraints —
  create parent + children, link them.
- You need to find "what's next" without full context — `bd ready` lists
  beads whose dependencies are satisfied.
- The user says "close that ticket", "reopen", "add a comment to", etc. —
  operate on beads.

Do NOT use `bd` for ephemeral session state (that's what your working
context is for) or for one-shot commands (that's what plain execution is
for). Beads is for work that outlives the conversation.

## Initialize once per repo

```
bd init                          # creates .beads/ (Dolt-backed graph)
```

`.beads/` should be in `.gitignore` unless the team is sharing beads via
git (uncommon).

## Core commands

| Intent | Command |
|---|---|
| Capture (fast) | `bd q "one-line task"` — emits ID only, ideal for scripting |
| Capture (rich) | `bd create "title" --priority high --labels bug,triage` |
| Add dependency | `bd link <child> <parent>` — child blocks on parent |
| See what's ready | `bd ready` — beads whose blockers are closed |
| Claim ownership | `bd claim <id>` |
| Change state | `bd set-state <id> <state>` (also creates an event) |
| Add reasoning | `bd note <id> "why we chose X"` — append note |
| Close | `bd close <id>` |
| Search text | `bd search "flaky test"` |
| Query graph | `bd query '<query-lang>'` — see `bd query --help` |
| Impact | `bd children <id>`, `bd graph <id>` |

## Discipline

- **One bead per surface**: a bug, a follow-up, a decision to revisit —
  never bundle unrelated work.
- **Link don't nest prose**: dependencies belong in `bd link`, not in the
  description.
- **Notes over edits**: prefer `bd note` (append) over `bd edit` (rewrite)
  when adding new information — preserves history.
- **Close with context**: `bd close <id> && bd note <id> "closed because X"`
  so a future search finds the reasoning.

## When Gas City is present

Inside a rig registered with `gc rig add`, prefer `gc bd ...` — it routes
through the supervisor and picks the correct rig's beads database
automatically. Plain `bd` walks up from cwd instead.

## Composes with

- **mg-watch** — live side-panel view of task state while you drive the DAG. Fires alongside `bd ready` / `bd claim` / `beads workflow`.
