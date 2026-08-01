---
name: spec-kit
description: For non-trivial features (multi-file, cross-cutting, or with unclear tech choices), use GitHub Spec Kit's constitution/spec/plan phases to produce durable design docs, then convert the plan into beads. Triggers on "let's plan this", "spec this out", "design first", "before we implement", "constitution for this repo", "new feature X", "what's the plan for Y". Do NOT run `/speckit.tasks` — that duplicates beads. See also [[beads]].
---

# spec-kit (`specify`) — design layer above beads

**Rule of the pipeline:** spec-kit owns *design artifacts* (immutable
markdown, git-committed). Beads owns *execution state* (mutable graph,
queryable, live). Use both. Never `/speckit.tasks`.

## Bootstrap per repo

```
specify init . --integration claude
```

Drops `memory/`, `spec/`, `plan/`, `.specify/`, and Claude Code slash
commands `/speckit.constitution`, `/speckit.specify`, `/speckit.plan`.
`.specify/` is already in the global gitignore.

## The composition, phase by phase

| Phase | Command | Artifact | Owner |
|-------|---------|----------|-------|
| Principles | `/speckit.constitution <principles>` | `memory/constitution.md` | spec-kit |
| WHAT | `/speckit.specify <feature description>` | `spec/<slug>.md` | spec-kit |
| HOW | `/speckit.plan <tech + architecture>` | `plan/<slug>.md` | spec-kit |
| Tasks | **skip `/speckit.tasks`** — `bd create` per unit of work | `.beads/` (graph) | beads |
| Execute | Claude implements bead-by-bead, `bd close` on completion | git commits | beads + git |

## Why skip `/speckit.tasks`

`/speckit.tasks` produces a flat markdown checklist. Beads gives you:

- Real dependency edges (`bd link a b`), not indentation
- `bd ready` — what's unblocked *right now*
- State machine (open / in_progress / closed / superseded)
- Priority, labels, notes appended over time, event history
- Queryable (`bd query`, `bd search`, `bd graph`)
- Visualisable (`bv` — beads-viewer TUI)

None of that lives in a `tasks.md` file. Once tasks exist, they belong in
beads.

## When to skip spec-kit entirely

Not every change needs a spec. Go straight to `bd create` when:

- Single-file, single-purpose change (typo, rename, small fix)
- Bug fix with known root cause — a bead + `bd note` covers it
- Exploration / spike — no spec until direction is settled

Reach for spec-kit only when the feature is large enough that a *future
reader* would want to know why, not just what.

## Boundary map (what lives where)

```
memory/constitution.md    spec-kit — governing principles, immutable-ish
spec/<feature>.md         spec-kit — the WHAT (user-visible behavior)
plan/<feature>.md         spec-kit — the HOW (tech, architecture)
docs/adr/*.md             separate — architecture decision records
.beads/                   beads — live execution graph
.gc/                      gascity — supervisor state, per-city config
```

Do not put tasks in `spec/` or `plan/`. Do not put design rationale in
beads (use `bd note` for execution-time context, not upfront design).

## Concrete flow for a new feature

1. `/speckit.constitution` (only if `memory/constitution.md` doesn't exist)
2. `/speckit.specify <what the feature does and why>`
3. `/speckit.plan <how, tech choices, module boundaries>`
4. Read `plan/<slug>.md` back, decompose into beads:

   ```
   bd create --title="…" --description="…" --type=task --priority=2
   bd link <blocked-id> <blocker-id>
   ```

5. `bd ready` → pick a bead → `bd update <id> --claim` → implement →
   `bd close <id>`
6. Repeat until `bd ready` is empty; the feature is done.
