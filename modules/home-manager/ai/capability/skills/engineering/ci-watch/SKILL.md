---
name: ci-watch
description: When the user pushes to GitLab, retries a job, or triggers a pipeline, open `glab ci view` scoped to the affected branch in a herdr split and auto-close it when the pipeline reaches a terminal state. Reach for this after any `git push`, `glab ci run`, or `glab ci retry` where the pipeline result matters to the current work.
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
