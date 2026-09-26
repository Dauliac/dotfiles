---
name: pre-commit-lint
description: Before every `git commit`, run the repo's own `fix` / `lint` / `build` / `test` gates via whichever task runner the repo declares (hk, mise, just, task, make) — in that priority order — and open the invocation in a herdr split so the user sees the run live. Enforces "respect the repo's linter even when the diff came from another editor" — foreign-editor auto-formatting does NOT exempt the diff from the repo's own gates. Triggers on "commit", "before commit", "pre-commit", "git commit", "about to commit", "wrap up", "ready to push", "run the linter", "run lint", "lint the diff", "fix formatting", "check my code", "make it standard", "before I push", or the moment before invoking `git commit`. Skips only for docs-only / config-only edits where the gates are meaningless. Composes with `mise-quality-gates` (the mise-only cousin — this skill supersedes it when non-mise runners are also present), `herdr-run` (for the visible pane), `mise-tasks` / `repo-tasks` (for runner detection and task discovery), `commit-rationale` (for the commit body once the gates pass).
---

# pre-commit-lint — visible, cross-runner lint/fix/build/test before commit

The rule the user paid to encode:

1. **Never commit without running the repo's own gates.** The gates are
   whatever the repo declares — `fix`, `lint`, `build`, `test` — under
   whichever task runner the repo already uses.
2. **Respect the repo's linter even when the diff came from another
   editor.** If VS Code / JetBrains / a teammate's Prettier reformatted
   something on save, that does NOT exempt the diff from *this* repo's
   configured lint/format. Editors and the repo disagree constantly.
   The repo's gate wins. Run it, and commit whatever it produces.
3. **Run the gates in a herdr split, not silent Bash.** The user wants
   to watch them go. Long output, mutating steps (`fix`), and the
   possibility of a failure to reason about all belong in a visible
   pane.
4. **Always include `build` when a `build` gate exists.** Even for
   changes that "obviously don't need a build" — obvious is wrong more
   often than the compiler.

## Runner priority (detect once, then commit to it)

Scan the repo root — first hit wins:

| Priority | Runner | Present when… | Reason it's first |
| --- | --- | --- | --- |
| 1 | **hk** | `hk.pkl`, `hk.toml`, `.hk.pkl`, or `hk` is in `.git/hooks/pre-commit` | Purpose-built for git-hook orchestration; parallel, cached, hash-aware |
| 2 | **mise** | `.mise.toml`, `mise.toml`, `.config/mise.toml`, `.mise/config.toml`, or `.mise/tasks/` | Encodes the exact flags + env the maintainer wants |
| 3 | **just** | `Justfile`, `justfile`, `.justfile` | Common lint/fix host in scripts-heavy repos |
| 4 | **Task** | `Taskfile.yml`, `Taskfile.yaml`, `Taskfile.dist.yaml`, `Taskfile.dist.yml` | Common lint/fix host in Go and CI-adjacent repos |
| 5 | **Make** | `Makefile`, `GNUmakefile`, `makefile` | Last-resort fallback |

If two runners share the same repo, pick the higher-priority one —
maintainers rarely wire the same target into both, and running twice
wastes time and can double-format. If it's ambiguous, ask the user
once and remember for the session.

If none exist, this skill has nothing runner-based to do — fall back
to whatever ad-hoc lint/format command the repo README documents, or
say so and stop.

## Discovery per runner

Only run the gates that actually exist. Do not invent them.

| Runner | Enumerate |
| --- | --- |
| hk | `hk --help` and `hk check --help` — hk exposes `check` (lint) and `fix`; `hk run <step>` for named steps. Read the config (`hk.pkl` / `hk.toml`) to see the declared steps. |
| mise | `mise tasks --hidden --name-only` |
| just | `just --list` |
| Task | `task --list-all` (falls back to `task --list` if not supported) |
| Make | `grep -E '^[a-zA-Z0-9_.-]+:' Makefile` — Make has no native listing; scan phony targets |

Look specifically for these four names, in this spelling:

- `fix` (also acceptable: `format`, `fmt`, `autofix` if the repo aliases them)
- `lint` (also acceptable: `check`, `vet`)
- `build`
- `test`

If a runner declares only some of the four, run only those. Do not
map `format` → `fix` silently across runners; verify with the
runner's own listing that the alias is real.

## Order and stop conditions

Run them in this order and **stop at the first failure**:

```text
1. fix     — mutates the tree, gets the free wins
2. lint    — catches what fix couldn't
3. build   — does it compile / assemble
4. test    — does it behave
```

Rationale (same as `mise-quality-gates`, generalized):

- `fix` first because it mutates files — running `lint` before `fix`
  wastes cycles reporting things `fix` would have silently corrected.
- `lint` before `build` because lint is usually cheaper and catches
  type / static errors early.
- `build` before `test` because tests can't run against a broken build
  and the failure is faster + clearer at the build layer.
- `build` runs **whenever a `build` gate exists**, even if the change
  "looks obviously non-compiling" — the user asked for this
  explicitly.

## How to invoke each gate

Every gate goes through `herdr-run` so the user sees the pane:

```bash
herdr-run <runner-invocation>
```

Examples:

```bash
herdr-run hk fix
herdr-run hk check
herdr-run mise run fix
herdr-run mise run lint
herdr-run mise run build
herdr-run mise run test
herdr-run just lint
herdr-run task lint
herdr-run make test
```

Long test / build runs may benefit from `--role gates` so the pane
sticks around for the whole four-step sequence rather than being
reused for other one-off runs:

```bash
herdr-run --role gates mise run fix
herdr-run --role gates mise run lint
herdr-run --role gates mise run build
herdr-run --role gates mise run test
```

For pure reads that inform the *next* command (e.g. `mise tasks
--name-only` while deciding what exists), plain Bash is fine — that's
inner-monologue plumbing, not something the user needs to watch.

## Respect the linter — foreign-editor edits are no exemption

The rule: **if the diff was produced by another editor (VS Code
auto-format on save, JetBrains reformat, a co-author's Prettier), you
still run this repo's `fix` and `lint` on it before committing.**

Why this matters:

- Editors carry their own opinionated defaults that drift from the
  repo's Prettier / rustfmt / golangci-lint / EditorConfig config.
- A diff that "looks clean" in VS Code can be a wall of red under the
  repo's own linter — indent width, quote style, trailing commas, and
  import order all diverge.
- CI runs the repo's gate, not the editor's. Skipping locally just
  moves the failure into someone else's pipeline.

So: when the user says "I already formatted it in my editor", "it's
already clean", or the diff visibly *is* auto-formatted — still run
`fix` and `lint` via the repo's runner. If they complain about the
extra churn: the answer is "the repo's linter is the source of
truth; if the two disagree, the fix is to reconcile the editor
config, not to skip the gate."

## Handling failures

On failure of any gate:

1. **Do not continue to the next gate** — later gates would either
   fail on the same cause or mask the real one.
2. **Read the failure verbatim, don't summarize it away.** Long stack
   traces and lint dumps often bury the actionable line at the very
   top or very bottom.
3. **Fix the root cause, not the gate.** Never `# noqa`, never
   `--no-verify`, never `--allow-empty`, never delete the failing
   test — those are how quality gates rot. If the gate itself is
   genuinely wrong, say so to the user and stop; don't patch it
   silently.
4. **After fixing, restart from `fix`.** Small edits can regress an
   earlier gate you thought was green (e.g. a test edit that
   introduces an unused import that `fix` would have caught).

## When to skip gates deliberately

Skipping is legitimate for a narrow set of changes. Say so out loud
when you skip:

- **Docs-only edits** (`*.md`, `*.rst`, comments) — no build/test
  value. `lint` may still apply if the repo lints Markdown; run only
  that one.
- **Config-only edits** that don't affect runtime (`.gitignore`,
  editor configs, CI YAML) — same as above.
- **Generated-file regeneration** where the generator is the test —
  the regen step *is* the gate.
- **Explicitly bypassed by the user** ("skip the tests, I'll run them
  after") — comply, but note in the handoff which gates you skipped
  so the user has a checklist.

Do **not** skip because "it's a small change" or "I'm sure it works"
or "my editor already reformatted it". Small changes fail tests all
the time. Editors disagree with linters. That's why the gates exist.

## Reporting back

When all applicable gates pass, the handoff line to the user should
name the runner, the gates, and any skips:

- `hk fix/check/build/test all pass`
- `mise fix/lint/build/test all pass`
- `just lint/build/test pass; fix not defined`
- `mise lint/build pass; test skipped (user request)`
- `mise lint pass; skipped fix/build/test (docs-only edit)`

When a gate fails and you couldn't fix it, hand back:

- Which runner, which gate, exit code, and the actionable error line
- What you tried (if anything)
- A recommendation: fix at root, revert, or escalate to the user

Never say "should be good" or "commit is safe" without having run
the gates. That's the exact phrase that ships broken code.

## Composes with

- **mise-quality-gates**: the mise-only cousin. When the repo has
  *only* a mise config and none of hk / just / Task / Make, defer to
  it — same order, same stop conditions, same forbidden shortcuts.
  This skill's contribution is (a) generalizing across runners,
  (b) mandating herdr-run visibility, (c) the "respect the linter
  against foreign editor edits" rule.
- **mise-tasks**: run first (once per session) when mise is the
  chosen runner to know what tasks actually exist.
- **repo-tasks**: if you find yourself about to type the same
  multi-flag lint invocation because the runner doesn't declare it,
  promote it into the runner file instead of running raw.
- **herdr-run**: the visibility mechanism. Every gate invocation
  goes through it.
- **hunk**: after `fix` mutates files, `hunk diff` in a review pane
  lets the user eyeball what auto-formatting touched before the
  commit lands.
- **commit-rationale**: gates pass → the commit body should note
  which gates ran green (part of the reasoning trail).
- **ci-watch**: after `git push`, the same gates run in CI — open
  `glab ci view` in a herdr split to catch environment-only failures
  the local run couldn't reproduce.
