---
name: repo-tasks
description: When a generic repo-level command deserves a permanent home (build, test, dev up/down, lint, format, check, install, deploy, migrate, clean, ...), add it to the repo's existing task runner file — Taskfile (task), Justfile (just), Makefile (make), or mise (.mise.toml) — instead of leaving it in chat as a raw shell one-liner. Delegates the read-docs → implement → verify loop to a nested agent so the parent context stays clean. Triggers when the user says "add a task", "make this a task", "put this in the Taskfile / Justfile / Makefile / mise", "wire this up as a command", "we keep running this — save it", or when you notice yourself explaining the same multi-flag invocation for the second time in a session. Does NOT trigger for one-off shell commands, project-specific ad-hoc scripts (use scratch-scripts), or CI-only jobs (those go in the CI config, not the task runner).
---

# repo-tasks — promote generic commands into the repo's task runner

Repos accumulate build/test/lint/dev incantations. If they aren't captured
in the repo's task runner file, they get re-typed, re-explained, and
forgotten across sessions. This skill wires *generic* commands into the
task runner the repo already uses, and does so via a nested agent so the
parent conversation doesn't have to load the tool's docs itself.

## What counts as "generic enough"

Add to the task runner when:

- The command is a **verb of the project lifecycle** — `build`, `test`,
  `lint`, `fmt`, `check`, `dev`, `dev:up`, `dev:down`, `deploy`,
  `migrate`, `seed`, `install`, `clean`, `docs`, `release`, `ci`.
- **Two or more people (or two or more sessions)** would plausibly want
  to run this exact incantation.
- The flag combo is **non-trivial to recall** (multi-line, env vars,
  ordered dependencies, cwd-sensitive).

Skip when:

- One-off cleanup or migration that won't repeat → run it, don't archive it.
- Personal shell dance across many projects → use **scratch-scripts**.
- CI-only orchestration → put it in the CI config directly, not in the
  task runner (unless the task runner *is* what CI invokes).
- The repo has no task runner file and the user hasn't asked to
  introduce one → propose, don't create unilaterally.

## Detection

Before anything else, scan the repo root (and one level down for
monorepos) for these files, in this priority order when multiple exist:

| Runner | File(s) | Docs entry point |
|---|---|---|
| Task | `Taskfile.yml`, `Taskfile.yaml`, `Taskfile.dist.yaml`, `Taskfile.dist.yml` | https://taskfile.dev/usage/ |
| just | `Justfile`, `justfile`, `.justfile` | https://just.systems/man/en/ |
| mise | `.mise.toml`, `mise.toml`, `.config/mise.toml`, `.mise/config.toml` | https://mise.jdx.dev/tasks/ |
| Make | `Makefile`, `GNUmakefile`, `makefile` | `man make` / https://www.gnu.org/software/make/manual/ |

Rules of engagement:

- **One file already exists** → use it. Don't second-guess the repo's
  choice.
- **Multiple exist** → prefer in the order Task > just > mise > Make
  *unless* the target task is already defined somewhere in one of them,
  in which case extend that file. When ambiguous, ask the user once.
- **None exist** → ask the user which runner to introduce before
  writing anything. Don't pick for them.

## The nested-agent contract

The parent (you) does the light work — detect the file, decide the task
name, hand off. The child does the tool-specific work — read the tool's
own docs, write the change, verify it runs. This keeps the parent's
context free of tool-manual noise.

Use `Agent` with `subagent_type: general-purpose` and a self-contained
prompt shaped like the template below. The child is **not** a persistent
worker — it reads docs, edits one file, runs one verification command,
returns proof, and exits.

### Prompt template for the child

```
You are wiring a new task into <RUNNER> for this repo.

Task runner file: <ABS_PATH>
Task name: <NAME>            (e.g. build, test, dev:up, lint)
Task intent: <ONE_SENTENCE>  (what the command should accomplish)
Command to wire: <SHELL>     (the incantation, verbatim, with env/cwd)
Dependencies: <OTHER_TASKS>  (or "none")

Do exactly this, in order:

1. READ the official docs entry point for <RUNNER> from your web fetch
   tool (URL above in the skill). Read only the pages relevant to
   declaring a new task with the features you need (deps, env vars,
   variables, silent mode, sources/generates, platform guards). Skim,
   don't archive.

2. READ <ABS_PATH> in full so your new task matches the file's style
   (variable naming, indentation, comment tone, task grouping).

3. EDIT <ABS_PATH> to add or update the task. Follow the existing
   conventions. Do not reformat unrelated tasks. Do not add tasks the
   user didn't ask for.

4. VERIFY by running the task once end-to-end:
   - Task:   `task <NAME>`
   - just:   `just <NAME>`
   - mise:   `mise run <NAME>`
   - Make:   `make <NAME>`
   Capture the exit code and the last 20 lines of output.

5. RETURN to the parent a short report in this exact shape:
   - Runner + file path
   - Task name added/updated
   - The exact diff hunk you wrote (no more than 40 lines)
   - Verification command run + exit code + tail
   - Anything the parent needs to know (e.g. "this task depends on
     `docker` being running", "requires `.env` present")

DO NOT open subagents of your own. DO NOT touch other files. DO NOT
commit. If verification fails, report the failure verbatim and stop —
do not iterate on the fix without instruction.
```

### What the parent does with the report

- Relay the diff + verification result to the user in 2-4 lines.
- Suggest a commit message if the user asked to commit; otherwise stop.
- If verification failed, decide with the user whether to iterate,
  revert, or hand off to a fresh child with new context.

## Style guardrails per runner

Style choices to nudge the child toward when the repo's existing file
doesn't already pin them down:

- **Task**: prefer `desc:` on every task (they show up in `task --list`),
  group with `:` namespaces (`dev:up`, `dev:down`), use `deps:` for
  ordered prerequisites, `silent: true` for tasks whose output would be
  noise.
- **just**: prefer lowercase kebab-case recipe names, use `@` prefix to
  silence the command echo when the recipe's own output is the point,
  put shared values in top-of-file `variable := "value"` assignments.
- **mise**: use `[tasks.<name>]` blocks with `description`, `run`, and
  `depends`; scope env in `[env]` at file top when the task needs it.
- **Make**: mark phony targets with `.PHONY:`, prefer `@` prefix on the
  recipe line to silence the command echo, use `$(VAR)` not `${VAR}`.

## Composes with

- **scratch-scripts**: for personal cross-project helpers that don't
  belong in *this* repo's task runner.
- **hunk**: after the child returns, `hunk diff <task-file>` lets the
  user eyeball the change before committing.
- **beads**: if promoting the command surfaces a broader "our task
  runner is a mess" observation, `bd create` it as a chore rather than
  fixing it inline in the same turn.
