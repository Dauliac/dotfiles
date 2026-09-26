---
name: mise-tasks
description: When entering a repo that has a mise config (`.mise.toml`, `mise.toml`, `.config/mise.toml`, `.mise/config.toml`, `.tool-versions` with `[tasks]`, or `.mise/tasks/`), enumerate every declared task — including hidden ones — with `mise tasks --hidden` before improvising shell one-liners. Triggers when you're about to run a build/test/lint/format/dev/check/deploy invocation in a repo where mise is present, when the user says "run the tests", "build this", "lint it", "how do I run X here", "what tasks are there", "what can mise do here", or the first time in a session you're about to type a raw command that might already exist as a mise task. Also triggers on "list mise tasks", "show mise tasks", "mise task discovery". Does NOT trigger in repos without a mise config — fall back to Taskfile/Justfile/Makefile detection there.
---

# mise-tasks — discover and prefer existing mise tasks

Repos that pin their toolchain with `mise` (see `mise-deps`) almost always
also declare **tasks** — `mise run build`, `mise run test`, `mise run
lint` — that encode the exact flags, env, and cwd the maintainer wants
you to use. Hidden tasks (`hide = true`) are especially easy to miss:
they don't show in `mise tasks` by default, but they're often the
building blocks the visible tasks depend on and are legitimate to invoke
directly during debugging.

**The reflex:** before typing a raw `pnpm test`, `cargo build`, `go
test ./...`, `terraform plan`, `nix build`, etc., check if mise already
has a named task for it. If yes, run the task. If no, run raw.

## Detection

Scan for any of these — presence of *any one* means mise tasks are in
scope:

```bash
ls -la .mise.toml mise.toml .config/mise.toml .mise/config.toml \
       .tool-versions 2>/dev/null
ls -d .mise/tasks mise-tasks 2>/dev/null
```

If none exist, this skill does not apply — fall through to the
`repo-tasks` skill's Taskfile/Justfile/Makefile detection instead.

## The enumeration

Run **once per session**, in the repo root, before you invoke any
mise-adjacent command:

```bash
mise tasks --hidden --extended
```

Flags matter:

- `--hidden` — includes tasks declared with `hide = true`. These are
  usually internal steps (`_setup`, `_precheck`, `install:internal`)
  that visible tasks depend on. Knowing they exist prevents you from
  rewriting one by hand.
- `--extended` — shows all columns (name, alias, description, source
  file, depends). The `source` column tells you *which* config file
  declares the task in a monorepo — critical when the same name is
  redefined at multiple levels.

If you only need names for piping (e.g. to grep or fzf):

```bash
mise tasks --hidden --name-only
```

For a specific task's full definition (env, deps, script body):

```bash
mise task info <name>
```

To see the dependency graph before running a task with many deps:

```bash
mise tasks deps <name>
```

## Decision after enumeration

Once you know what's there:

| Situation | Action |
|---|---|
| A task matches the intent exactly (`test`, `build`, `lint`, `fmt`) | `mise run <name>` — do not re-invent the flags |
| Several tasks partially match (`test:unit`, `test:integration`, `test:e2e`) | Ask the user which layer they want, or run the umbrella (`test`) if one exists |
| A hidden task is the actual entry point | Run it explicitly with `mise run <name>` — hidden ≠ private, it just means "not surfaced in the default list" |
| Nothing matches | Free to run raw. If the invocation is worth keeping, escalate to `repo-tasks` to promote it into `[tasks.*]` |
| Task exists but is broken / outdated | Report it, don't silently bypass — the maintainer wants to know |

## Gotchas

- **Monorepo scope**: by default `mise tasks` only lists tasks reachable
  from the current directory's hierarchy. Add `--all` if you're standing
  at the root of a monorepo and need to see sibling packages' tasks
  too. Otherwise you'll miss half the surface.
- **`.tool-versions` alone**: a bare `.tool-versions` file pins tools
  but declares no tasks. Detection still fires, enumeration will just
  return an empty list — that's fine, move on.
- **`[tasks.*]` in TOML vs file tasks in `.mise/tasks/`**: mise reads
  both. `mise tasks` merges them; you don't need to look at each source
  separately.
- **Task aliases**: the `alias` column in `--extended` output is not
  cosmetic — an alias is a first-class name. `mise run <alias>` works.
- **Do not confuse `mise tasks` with `mise task`** (singular): `mise
  task` is a subcommand namespace (`task info`, `task add`, `task
  edit`). The listing verb is plural.

## Composes with

- **mise-deps**: mise-deps pins the *tools*, this skill discovers the
  *tasks*. They're siblings.
- **repo-tasks**: when you run raw because no mise task matched and the
  invocation deserves a permanent home, hand off to `repo-tasks` to
  wire it into `[tasks.*]`.
- **mise-quality-gates**: after enumeration, that skill decides which
  of `fix` / `lint` / `build` / `test` (if present) to run before
  declaring work done.
- **herdr-run**: long-running tasks (`build`, `test`, `dev`) belong in a
  visible pane. Prefix with the herdr-run reflex if the user would want
  to watch.
