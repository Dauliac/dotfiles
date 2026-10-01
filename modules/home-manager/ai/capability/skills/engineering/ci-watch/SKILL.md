---
name: ci-watch
description: Open `glab ci view` in a herdr split, scoped to the affected branch, and auto-close it when the pipeline reaches a terminal state. Fires in TWO cases  -  (a) something just triggered a pipeline (`git push`, `glab ci run`, `glab ci retry`, `glab mr create`), (b) the user asks to look at an already-running pipeline. Case (b) triggers include literal phrases "watch the pipeline", "watch CI", "watch the CI", "watch the jobs", "watch the job", "watch the deploy", "check CI", "check the CI", "check the pipeline", "check the jobs", "check the job", "look at CI", "look at the CI", "look at the pipeline", "look at the jobs", "look at jobs", "look at the job", "monitor the pipeline", "monitor CI", "tail the pipeline", "tail CI", "show me CI", "show me the pipeline", "show me the jobs", "open CI", "open the pipeline", "is CI passing", "did CI pass", "did CI fail", "why did CI fail", "which job failed", "jobs failing", "pipeline status", "CI status", "GitLab pipeline", "GitLab CI", or any ask of the form "<see/show/look at/watch/check/monitor/tail> <CI | pipeline | jobs | the pipeline | GitLab>". Do NOT skip just because no `git push` happened in this turn  -  the observational ask alone is enough.
---

# ci-watch — live GitLab pipeline TUI, scoped and self-closing

Triggered whenever a GitLab pipeline is now the interesting thing to watch:

- After `git push` to a branch that has GitLab CI.
- After `glab ci run` / `glab ci retry` / `glab mr create`.
- When the user asks "why did CI fail?" and you want them to see it live.

## Single-TUI case (default)

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
herdr-tui launch \
  --label "ci:$BRANCH" \
  --auto-close-when "s=\$(glab ci status -b $BRANCH -F json 2>/dev/null | jq -r '.status // empty'); \
                     test \"\$s\" = success || test \"\$s\" = failed || test \"\$s\" = canceled || test \"\$s\" = manual" \
  --auto-close-timeout 3600 \
  -- glab ci view "$BRANCH"
```

The predicate: pipeline reached a **soft-terminal** state — `success`,
`failed`, `canceled`, or `manual`. Hard cap at 1 hour so a stuck poll
never leaks a pane forever.

`manual` is soft-terminal on purpose: the pipeline is quiescent
waiting for a human to fire a gate. Closing the split lets the operator
answer the `AskUserQuestion` from `glab-ci-manual-triage` without a
stale pane in the way; the triage skill either re-opens ci-watch or
`glab-push-flow` re-arms it after firing.

If `glab ci status -F json` isn't supported by the installed glab, fall back
to grepping `glab ci status -b $BRANCH` for `status=success|failed|canceled`.

## Multi-TUI case

If ci-watch runs alongside `k8s-watch` or `s3-watch` in the same session,
share one grid instead of stacking splits — see [tui-context](#) for the
`grid-open` / `grid-add` flow.

## Claude-side wait (background, not TUI)

`ci-watch` is for the *human* to watch. If Claude needs to keep the
workflow moving and resume once the pipeline reaches a terminal state
(commit next step, notify, transition a bead), use [`async-wait`](../async-wait/SKILL.md)
in addition to — not instead of — this skill.

**Mandatory pairing rule:** every active CI poll (see `async-wait` §4a)
MUST launch the `ci-watch` split alongside so the human has parallel
visibility. Only skip in explicit headless / non-interactive runs.

## Fail-fast pairing

For fail-fast polling (return on first non-`allow_failure` failed job
rather than whole-pipeline terminal state), use the scratch helper
`~/.cache/claude/scratch/glab_ci_wait_failfast.sh <pipeline-id>`. It:

- launches this `ci-watch` split at start (deduped via `herdr-find`
  against the `ci:$BRANCH` label — no duplicate pane if one is already
  open),
- polls `glab ci get -F json --with-job-details` every 25 s,
- on first non-`allow_failure` failed job: prints
  `{id, name, stage, url, reason}` + last 200 log lines to stdout, and
  opens `glab ci trace <jid>` in a follow-up split labeled `trace:<jid>`
  (auto-closes after 5 min idle, hard cap 30 min),
- on **MANUAL_BLOCKED** (every non-manual job settled + ≥1 manual job
  pending): emits `MANUAL_BLOCKED pipeline=<pid> count=<n>` + JSON
  array of `{id, name, stage, allow_failure, environment, web_url}` to
  stdout and exits **5** — callers route via `glab-ci-manual-triage`
  (AskUserQuestion per gate) then re-invoke the poller,
- exits `0` success / `1` failure / `2` canceled / `3` timeout / `4`
  args/auth / `5` manual-blocked.

Two splits max: `ci:$BRANCH` (the overview) and `trace:$JID` (the
failure log). Per `herdr-layout`, if a third TUI would join the session
(e.g. `k8s-watch`), promote all three to a grid tab via `tui-context`
`grid-open` / `grid-add` instead of stacking vertical splits.

## Failure mode

If `glab` isn't logged into the current host or the branch has no pipeline,
`glab ci view` will bail immediately. Don't spawn the pane in that case —
run `glab ci status -b "$BRANCH"` in plain Bash first; only launch the TUI
if you see a pipeline id.

## Composes with

- **glab-push-flow** — the always-on post-push orchestrator invokes
  this skill for the human's foreground visibility (step 3), while
  also arming the background poller (step 4).
- **async-wait** §4a — Claude-side background wait; MUST be paired
  with a ci-watch split (this skill) whenever polling a pipeline.
- **glab-ci-manual-triage** — receives control when the pipeline
  hits `manual` state (soft-terminal above); asks the human which
  gates to fire, then hands back to `glab-push-flow` to re-arm.
- **glab-mr-automerge** — arms MWPS so that on `success` this split
  closes AND the MR merges automatically.
- **glab-mr-ready** — its readiness report's "Pipeline `manual`" row
  delegates to `glab-ci-manual-triage`, same downstream path.
- **tui-context** / **herdr-layout** — grid layout when a third TUI
  joins (k8s-watch / s3-watch).
- **scratch-scripts / glab_ci_wait_failfast.sh** — the fail-fast
  poller referenced above.
