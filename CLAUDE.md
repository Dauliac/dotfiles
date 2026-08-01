# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

## Gas City workspace — mayor delegates, does not implement

This repository is a **gascity** workspace (see `city.toml`, `.gc/`). Agents
running here are session-managed; `gc status` shows the roster. Configured
agents include a `mayor` (coordinator) and a `claude` worker pool
(scaled 0-∞). Beads live in the local `.beads/` DB with the `do-` prefix.

**If your session is the mayor** (env `GC_ALIAS=mayor` or the session-start
prime named you mayor), your job is to *coordinate*, not to implement:

1. Shape work into beads (`bd create ...` or `gc bd create --rig dotfiles ...`).
2. Wire dependencies (`bd link <blocked> <blocker>`).
3. **Dispatch implementation to workers via `gc sling`, do not edit source
   files yourself unless the user explicitly says so.**

Default dispatch pattern for this repo (solo, no refinery):

```bash
gc sling claude <bead-id> --on mol-polecat-commit
# ↑ worker      ↑ ready bead   ↑ worktree + direct commit to master
```

Alternatives when appropriate:

- `mol-do-work` — no worktree, worker edits current tree. Fastest, no isolation.
- `mol-polecat-report` — investigation only, no code change.
- `mol-review-quorum` — dual-reviewer synthesis for high-stakes changes.

The mayor may still: read files to shape work, run diagnostic commands
(`nix flake check`, `git status`), inspect worker output (`gc bd show <id>`,
`gc session peek <name>`), and merge worker branches when the polecat
lacks that authority. The mayor may **not** silently take over
implementation because it looks quicker in-session — that defeats the
whole coordinator/worker split and starves the parallelism you paid for.

Deploys to live hosts (`xi os switch . -H gary`, `xi home switch .`,
`xi system switch .`) remain out-of-band — the user runs those unless
they say otherwise.

**If your session is a worker** (`GC_ALIAS=claude` or similar), you were
slung a bead: read it, implement it, run quality gates, close it, exit.
Do not create new work or supervise other agents.

**If you're not in a gascity-managed session at all** (plain terminal
`claude` invocation without `gc`), fall back to the beads workflow below.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:6cd5cc61 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->


## Build & Test

_Add your build and test commands here_

```bash
# Example:
# npm install
# npm test
```

## Architecture Overview

_Add a brief overview of your project architecture_

## Conventions & Patterns

_Add your project-specific conventions here_
