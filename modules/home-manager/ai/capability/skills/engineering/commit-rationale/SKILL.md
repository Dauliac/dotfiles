---
name: commit-rationale
description: When about to run `git commit`, write a body that carries the full reasoning trail — analysis, evidence, metrics, alternatives, verification — so a future human or agent reading `git log` can reconstruct *why* without re-running the investigation. Triggers on "commit", "commit this", "git commit", "make a commit", "wrap this up", or any time you're about to invoke `git commit`. Complements `mm-skills-git-commit-craft` (which shapes the *title* + splits): this skill shapes the *body*.
---

# commit-rationale — commits that carry their own reasoning

A commit title tells you *what* changed. The body has to answer *why this,
why now, and how do we know it's right* — so someone reading `git log -p`
six months from now (human or agent) does not have to re-run the
investigation. Diffs age well; context does not, unless we write it down.

## When to reach for it

- Any commit whose motivation is not obvious from the diff alone. Bug
  fixes, perf tweaks, refactors driven by a metric, migrations,
  configuration changes justified by an incident, security fixes,
  reverts, cross-module rewiring.
- Commits chained to an OpenSpec change, a bead, an incident, or an
  external ticket — the trail needs to survive the tools.
- Anything an agent is committing on behalf of the human: the body is
  the primary artifact the human has to audit the agent's judgment.

Skip it (title-only is fine) for: pure formatting/rename/whitespace,
dependency lockfile bumps whose only signal is the version diff,
generated-file syncs.

## Body structure

Keep the title in conventional-commits form (`feat`, `fix`, `refactor`,
`chore`, ...) — that stays owned by `mm-skills-git-commit-craft`. Then a
blank line, then the body. Use only the sections that carry real signal
— empty scaffolding is worse than no scaffolding.

```text
<type>(<scope>): <imperative subject, ≤72 chars>

Why:
  1-3 sentences on the problem or goal driving the change. What was
  broken, what metric we're moving, what constraint appeared. If a
  ticket / bead / incident / OpenSpec change is the origin, name it.

What changed:
  Bulleted list of the meaningful edits, keyed to file/path. Skip the
  obvious ones the diff already shouts. Call out anything a reader
  would miss (invariant swapped, feature flag flipped, default reversed).

Evidence:
  The proof. Before/after numbers, error traces, benchmark output,
  screenshot paths, log lines, repro command. If a claim can be
  measured, measure it — do not fabricate.

Alternatives considered:
  What else was on the table and why it lost. One line each. Omit if
  there was only one reasonable path.

Verification:
  What you actually ran to convince yourself. `nix flake check`,
  `just test`, manual repro steps, deploy-and-watch. Include the
  command so the next person can re-run it.

Refs:
  bd:<id>, openspec:<slug>, incident:<id>, PR: <url>, upstream: <url>
```

## Rules

- **No fabrication.** If you did not run the benchmark, do not paste
  numbers. If a test was not executed, do not claim it passed. An
  agent inventing evidence in a commit body is worse than an empty
  body — it poisons the audit trail.
- **Wrap at 72 columns.** `git log` still assumes it. Long URLs are
  the accepted exception.
- **No secrets, no PII, no host-internal paths that leak infra.**
  Commits are immutable and often mirrored; scrub before writing.
- **Link, do not paste** for anything > ~30 lines (long benchmarks,
  full stack traces). Reference the artifact by path or URL. If the
  artifact is ephemeral, summarize it and keep the raw dump out of
  git.
- **Present tense, imperative for the subject; past tense for the
  body** ("Reduced p99 from 340ms to 180ms" — you already made the
  change).
- **One commit, one thesis.** If the body needs two "Why" sections,
  the commit needs to be split. Hand off to
  `mm-skills-git-commit-craft`.

## Author the body via HEREDOC

Multi-paragraph messages via `-m "..."` break formatting. Always:

```bash
git commit -m "$(cat <<'EOF'
fix(auth): stop retrying 401 forever on refresh-token expiry

Why:
  Users signed out for > refresh-token-TTL hit an infinite retry loop
  in the interceptor — 30k requests/user/min against /oauth/refresh,
  visible as the 2026-02-14 support spike (incident:INC-8821).

What changed:
  - src/http/interceptor.ts: bail out of the retry chain when the
    refresh call itself returns 401. Redirect to /login instead.
  - src/http/interceptor.test.ts: cover the expired-refresh path.

Evidence:
  Before: repro script hits /oauth/refresh 1000x in 4s.
  After:  1 call, then 302 -> /login. Datadog dashboard "auth-retry"
          panel confirms the retry curve is flat on staging.

Verification:
  just test src/http
  bash scripts/repro-INC-8821.sh   # exits 0 now, was infinite loop.

Refs:
  bd:auth-42, incident:INC-8821
EOF
)"
```

Reasons this matters:

- Newlines survive. `-m "a\nb"` does not do what you want on any shell.
- Single-quoted HEREDOC (`<<'EOF'`) disables interpolation — safe for
  bodies containing `$`, backticks, `!`, `${...}`.
- Copy-paste-runnable from `git log --format=%B` if someone wants to
  quote you exactly.

## Amending vs. new commit

If pre-commit hooks reject the commit, the commit did **not** happen —
fix, re-stage, write a **new** commit. Do not `--amend`. `--amend`
after a hook failure amends the *previous* commit, which is either
someone else's or your last-good work.

Only `--amend` when the user explicitly asks, and the target is
unpushed.

## Composes with

- **`mm-skills-git-commit-craft`**: owns the subject line style,
  splitting a big diff into atomic commits, and the overall commit
  strategy. This skill owns what goes *inside* the body of each of
  those commits.
- **`beads` / OpenSpec**: the "Refs:" line is the durable bridge back
  to the live trackers. If a bead drove the work, cite it — the diff
  alone will not tell the next session which bead this closed.
- **`hunk`**: run `hunk diff` before writing the body — reviewing the
  final diff is how you know what to describe.
