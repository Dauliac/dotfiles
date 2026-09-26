---
name: mise-quality-gates
description: Before declaring a change done in any repo with a mise config, run the standard quality gates that mise exposes — `mise run fix`, `mise run lint`, `mise run build`, `mise run test` — for whichever of the four are actually declared. Enforces "code is standard" by matching what CI will run. Triggers when you're about to say "done", "ready to commit", "ready to review", "changes complete", "should be good now", when the user says "check my code", "make sure it's standard", "run the checks", "verify", "before I commit", "wrap this up", or before invoking `git commit` on a repo that has a mise config. Does NOT trigger in repos without a mise config, and does NOT trigger for docs-only / config-only edits where compile+test are meaningless.
---

# mise-quality-gates — run mise fix/lint/build/test before done

If a repo declares mise tasks named `fix`, `lint`, `build`, or `test`,
those are the canonical, agreed-upon quality gates for the repo. CI runs
them; humans run them; you run them too before declaring work done.
Skipping them means shipping code that fails on someone else's machine
first — the exact failure mode mise exists to prevent.

**The reflex:** when a change is about to be handed back (commit, PR,
"done"), run the four gates that exist, in order, and fix or report
failures before returning to the user.

## Detection

Prerequisite: this skill only applies when a mise config exists — see
`mise-tasks` for the detection list. If mise isn't in the repo, this
skill doesn't fire.

Given mise is present, enumerate what actually exists (do this from
memory if `mise-tasks` already ran this session; otherwise run it):

```bash
mise tasks --hidden --name-only
```

Look specifically for these four names, in this exact spelling:

- `fix` — auto-fixable lint / format
- `lint` — non-auto-fixable checks (typecheck, static analysis, style)
- `build` — compile / assemble
- `test` — unit + integration tests

**Only run the ones that exist.** Do not invent them. Do not
substitute `format` for `fix` unless the repo has explicitly aliased
them (check `mise tasks --extended` for the `alias` column). If none
of the four exist, this skill has nothing to do — fall back to whatever
gates the repo actually declares (Taskfile / Makefile / package.json
scripts).

## Order and stop conditions

Run them in this order and **stop at the first failure**:

```bash
mise run fix     # 1. mutate the tree — get the free wins
mise run lint    # 2. catch what fix couldn't
mise run build   # 3. does it compile
mise run test    # 4. does it behave
```

Rationale for the order:

- `fix` first because it mutates files — running `lint` before `fix`
  wastes cycles reporting things `fix` would have silently corrected.
- `lint` before `build` because lint is usually cheaper than a full
  build and catches type errors early.
- `build` before `test` because tests can't run against a broken build
  and the failure is faster + clearer at the build layer.

## Handling failures

On failure of any gate:

1. **Do not continue to the next gate** — the state is dirty; later
   gates would either fail on the same cause or mask the real one.
2. **Read the failure verbatim, don't summarize it away.** Long stack
   traces or lint dumps often bury the actionable line at the very
   top or very bottom.
3. **Fix the root cause, not the gate.** Never `# noqa`, never
   `--no-verify`, never delete the failing test — those are how
   quality gates rot. If the gate itself is genuinely wrong, say so
   to the user and stop; don't patch it silently.
4. **After fixing, restart from `fix`.** Small edits can regress an
   earlier gate you thought was green (e.g. a test edit that introduces
   an unused import).

## When to skip gates deliberately

Skipping is legitimate for a narrow set of changes. Say so out loud when
you skip:

- **Docs-only edits** (`*.md`, `*.rst`, comments) — no build/test value.
  `lint` may still apply if the repo lints Markdown; run only that one.
- **Config-only edits** that don't affect runtime (CI YAML, editor
  configs, `.gitignore`) — same as above.
- **Generated-file regeneration** where the generator is the test — the
  regen step *is* the gate.
- **Explicitly bypassed by the user** ("skip the tests, I'll run them
  after") — comply, but note in the handoff which gates you skipped so
  the user has a checklist.

Do **not** skip because "it's a small change" or "I'm sure it works".
Small changes fail tests all the time; that's why the gates exist.

## Reporting back

When all applicable gates pass, the handoff line to the user should be
one of:

- `mise fix/lint/build/test all pass` (when all four ran green)
- `mise lint/build/test pass; fix not defined` (missing one)
- `mise build/test pass; skipped lint (docs-only edit)` (skipped one)

When a gate fails and you couldn't fix it, hand back:

- Which gate, exit code, and the actionable error line
- What you tried (if anything)
- A recommendation: fix at root, revert, or escalate to the user

Never say "should be good" without having run the gates. That's the
exact phrase that ships broken code.

## Composes with

- **mise-tasks**: run first (once per session) to know what tasks exist
  so this skill doesn't have to re-enumerate.
- **hunk**: run `hunk diff` after `fix` mutates files so the user sees
  what auto-formatting touched before commit.
- **commit-rationale**: gates pass → commit message body should note
  which gates ran green (part of the reasoning trail).
- **ci-watch**: after push, the same gates run in CI — open `glab ci
  view` in a herdr split to catch environment-only failures the local
  run couldn't reproduce.
