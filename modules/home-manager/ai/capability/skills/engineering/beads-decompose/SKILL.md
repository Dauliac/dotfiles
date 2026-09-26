---
name: beads-decompose
description: Turn a plan / task list / spec into a bead DAG with proper dependency edges and consistent labels — one bead per unit of work, `bd link <child> <parent>` for order, `bd create --labels …` for grouping. **When the source is an OpenSpec change (`openspec/changes/<slug>/tasks.md`), PREFER `beads-plan plan <change-dir>` instead — it stamps `tier`/`complexity`/`parallelism`/`change` metadata this skill does not, and `beads-flow` uses that metadata to route.** Trigger on "decompose this into beads", "plan this into tasks", "make a todo out of this", "split into sub-tasks", "bead DAG from <spec>", or when a new long-horizon effort (ticket, refactor, incident, change) starts and the todo is more than 2 items. Emits the created IDs so the caller can hand them to `beads-flow` for execution.
---

# beads-decompose — plan → DAG

Take a linear plan and stamp it into beads with correct dependency
edges + consistent labels so `bd ready` gives a useful "what's next"
across the effort.

## When to reach for it

- Starting a support ticket / incident / feature / refactor whose
  work is more than 2 steps and worth resuming across sessions.
- Handed a `tasks.md` from an OpenSpec change (`openspec/changes/
  <slug>/tasks.md`) — decompose it.
- A colleague asks "how do we track this" — beads > markdown TODO.

Do NOT reach for it for one-shot work (one commit, one command, one
question). That's execution, not planning.

## Prerequisites

- `bd` on PATH and `bd doctor` green — see the `beads` skill for
  the base surface (`bd create`, `bd link`, `bd ready`, `bd note`,
  `bd close`).
- A clear list of units of work — either explicit (tasks.md,
  bulleted plan) or derivable from a template (see below).

## Discipline

- **One bead per unit of work.** Not "explore + fix + answer" as one
  bead — three beads, linked.
- **Ordering via `bd link`, not prose in the description.** Prose
  rots; edges are queryable.
- **Consistent labels** for grouping across efforts:
  - `<domain>:<id>` — e.g. `ticket:PLAT-4012`, `change:add-retry`
  - `phase:<name>` — e.g. `phase:explore`, `phase:review`
  - `env:<env>` — for deploy sub-beads (`env:dev`, `env:staging`, `env:prod`)
  - `blocking:human` — for beads that need explicit operator input
- **Descriptions link out**, not inline: `openspec: openspec/changes/
  <slug>/design.md § step 3` or `try-dir: ~/src/tries/2026-09-08-
  support/PLAT-4012/proof.md`.
- **Titles are imperative + short**: `Set Platform Capability`, not
  `Setting the Platform Capability on the ticket`.

## Core recipe

```bash
# 1. Root bead — the ticket / change / effort itself
root=$(bd q "PLAT-4012 — remove obsolete legacy hostnames" \
  --labels "ticket:PLAT-4012" --priority high)

# 2. Phase beads — one per unit
capa=$(bd q     "Set Platform Capability on PLAT-4012" --labels "ticket:PLAT-4012,phase:set-capability")
explore=$(bd q  "Explore + reproduce PLAT-4012"        --labels "ticket:PLAT-4012,phase:explore")
fix=$(bd q      "Design fix for PLAT-4012"             --labels "ticket:PLAT-4012,phase:fix-design")
impl=$(bd q     "Implement PLAT-4012 + open MR"        --labels "ticket:PLAT-4012,phase:implement")
ci=$(bd q       "PLAT-4012 pipeline green"             --labels "ticket:PLAT-4012,phase:ci-green")
review=$(bd q   "PLAT-4012 review cycle"               --labels "ticket:PLAT-4012,phase:review")
merge=$(bd q    "PLAT-4012 merge MR"                   --labels "ticket:PLAT-4012,phase:merge")
tag=$(bd q      "PLAT-4012 tag release"                --labels "ticket:PLAT-4012,phase:tag")

# Related-MR watch beads — one per unique URL from related-mrs.txt
# (produced by jira-ticket's step 4b from jiraai-review --deep).
# Labelled blocking:human — the operator opts in because watching a
# repo you don't own is a preference, not a mandate.
if [ -s "$ticket_dir/related-mrs.txt" ]; then
  while IFS= read -r mr_url; do
    [ -n "$mr_url" ] || continue
    bd q "Watch related MR: $mr_url" \
      --labels "ticket:$ticket,phase:watch-related-mr,blocking:human"
  done < "$ticket_dir/related-mrs.txt"
fi
dep_dev=$(bd q  "PLAT-4012 deploy dev"                 --labels "ticket:PLAT-4012,phase:deploy,env:dev")
ver_dev=$(bd q  "PLAT-4012 verify dev"                 --labels "ticket:PLAT-4012,phase:verify,env:dev")
dep_stg=$(bd q  "PLAT-4012 deploy staging"             --labels "ticket:PLAT-4012,phase:deploy,env:staging")
ver_stg=$(bd q  "PLAT-4012 verify staging"             --labels "ticket:PLAT-4012,phase:verify,env:staging")
dep_prd=$(bd q  "PLAT-4012 deploy prod (MANUAL gate)"  --labels "ticket:PLAT-4012,phase:deploy,env:prod,blocking:human")
ver_prd=$(bd q  "PLAT-4012 verify prod"                --labels "ticket:PLAT-4012,phase:verify,env:prod")
answer=$(bd q   "PLAT-4012 draft reporter answer"      --labels "ticket:PLAT-4012,phase:answer")
close=$(bd q    "PLAT-4012 post reply + Done"          --labels "ticket:PLAT-4012,phase:close")

# 3. Dependency edges (child blocks on parent)
bd link "$fix"     "$explore"
bd link "$impl"    "$fix"
bd link "$ci"      "$impl"
bd link "$review"  "$impl"
bd link "$merge"   "$ci"
bd link "$merge"   "$review"
bd link "$tag"     "$merge"      # skip if repo is not tag-managed
bd link "$dep_dev" "$tag"        # or "$merge" when no tag
bd link "$ver_dev" "$dep_dev"
bd link "$dep_stg" "$ver_dev"
bd link "$ver_stg" "$dep_stg"
bd link "$dep_prd" "$ver_stg"
bd link "$ver_prd" "$dep_prd"
bd link "$answer"  "$ver_prd"
bd link "$close"   "$answer"
bd link "$close"   "$capa"       # capability blocks close regardless of code path

# 4. Write the id map into the try dir so downstream skills can find them
cat > "$ticket_dir/beads.json" <<EOF
{
  "root": "$root", "capa": "$capa", "explore": "$explore",
  "fix": "$fix", "impl": "$impl", "ci": "$ci", "review": "$review",
  "merge": "$merge", "tag": "$tag",
  "dep_dev": "$dep_dev", "ver_dev": "$ver_dev",
  "dep_stg": "$dep_stg", "ver_stg": "$ver_stg",
  "dep_prd": "$dep_prd", "ver_prd": "$ver_prd",
  "answer": "$answer", "close": "$close"
}
EOF
```

## Ready-made templates

| Effort type | Template location |
| --- | --- |
| Support ticket (PLAT) | `jira-ticket` skill — the recipe above IS its template |
| OpenSpec change | Read `openspec/changes/<slug>/tasks.md`; one bead per checkbox; walk file order for edges |
| Refactor across N files | One bead per file / logical group; parallel by default; add sync beads (`cross-file consistency check`) for handoffs |
| Incident | `triage → mitigate → root-cause → fix → post-mortem` linear DAG |

## From tasks.md (OpenSpec / generic markdown checklist)

```bash
# Parse "- [ ] Title" lines from tasks.md; one bead each; linear deps.
prev=""
while IFS= read -r line; do
  case "$line" in
    "- [ ] "*)
      title=${line#- \[ \] }
      id=$(bd q "$title" --labels "change:$slug,source:tasks.md")
      [ -n "$prev" ] && bd link "$id" "$prev"
      prev=$id
      ;;
  esac
done < openspec/changes/$slug/tasks.md
```

**For OpenSpec-sourced tasks.md, always prefer `beads-plan plan <change-dir>`.** The linear parser above discards structure; `beads-plan` parses tasks.md + proposal.md + design.md + specs/, assesses complexity, assigns tier (`fast`/`standard`/`advanced`), analyzes parallelism (`parallel`/`sequential`/`mixed` + `parallel_groups`), and stamps a `change:<slug>` label so `beads-flow` can scope its loop and dispatch by tier. Use the shell recipe above only for ad-hoc / non-OpenSpec plans.

## Anti-patterns

- **One giant bead titled "do the ticket"** — defeats `bd ready`;
  future you can't see progress. Decompose upfront.
- **Chain of prose in one description** — describes what's "next" in
  a body paragraph instead of `bd link`. Loses queryability.
- **Labels-in-title** (`[explore] Do X`) — labels are structured
  metadata; use `--labels`.
- **Silent template drift** — if the DAG shape changes (e.g., a new
  mandatory phase), update the caller's template AND file a bead to
  backfill existing efforts.

## Composes with

- **beads** — the base CLI + discipline.
- **beads-flow** — the runtime that picks up ready beads and drives
  execution once decomposition is done.
- **jira-ticket** — the concrete template for support tickets calls
  this at setup time.
- **openspec-propose / opsx:propose** — the design step whose
  `tasks.md` this skill turns into a live DAG.
