---
name: glab-ci-manual-triage
description: Triage GitLab CI manual jobs blocking a pipeline. Lists every manual/action job on the pipeline via `glab api projects/:id/pipelines/:id/jobs?scope=manual`, formats each as {name, stage, allow_failure, description}, uses AskUserQuestion to ask the operator which to FIRE, which to SKIP, and which to DEFER (leave pending). Fires the selected gates via `glab api POST projects/:id/jobs/:jid/play` and reports back. Atomic — one pipeline id in, decisions and side-effects out. Trigger on "manual job blocked", "which manual jobs to run", "trigger the deploy gate", "pipeline waiting on manual action", "gate blocked the pipeline", "should I run the manual job", "the fail-fast poller exited 5", "MANUAL_BLOCKED stanza on stdout", "MWPS won't fire because manual gate", or the standing rule "if the pipeline is blocked by a manual job, ask which to trigger". Composes under `glab-push-flow` and is the mandatory next step for `async-wait §4a` on exit code 5.
---

# glab-ci-manual-triage — ask the human which gates to fire

Manual jobs in GitLab pipelines are ambiguous: some are "deploy to
staging on demand" (safe to fire without thinking), some are "release
to prod" (do NOT fire without a human), some are legacy dead gates
that nobody remembers to skip. Auto-firing all of them is
irresponsible; auto-firing none blocks the pipeline forever.

The right move: enumerate them, show the operator context per gate,
and use `AskUserQuestion` to route each one.

## Prerequisites

- `glab auth status` OK on the target host.
- A pipeline id (`$PID`) — from `glab ci status -F json | jq -r .id`,
  or handed in by the caller.
- `AskUserQuestion` tool available in the current agent runtime
  (Claude Code default — always available).

## The probe — one glab call

```bash
export GITLAB_HOST=<self-hosted-host-if-any>
REPO="${REPO:-}"                        # optional --repo GROUP/PROJ
REPO_ARG=()
[ -n "$REPO" ] && REPO_ARG=(-R "$REPO")

PID="${1:?usage: glab-ci-manual-triage <pipeline-id> [REPO=group/proj]}"

PROJ=$(glab ci get "${REPO_ARG[@]}" -p "$PID" -F json | jq -r .project_id)

# Manual jobs on this pipeline, ordered stage-then-name
MANUAL=$(glab api "projects/$PROJ/pipelines/$PID/jobs?scope[]=manual&per_page=100" \
  | jq -c '[.[] | {
      id, name, stage,
      allow_failure,
      environment: (.environment?.name // ""),
      web_url,
      status,                            # usually "manual" or "created"
      created_at
    }] | sort_by(.stage, .name)')

COUNT=$(jq 'length' <<<"$MANUAL")
[ "$COUNT" -eq 0 ] && { echo "no manual jobs on pipeline $PID"; exit 0; }
```

## The prompt — one AskUserQuestion per gate (or a batch)

**Small pipelines (≤3 manual jobs):** ask one `AskUserQuestion` per
gate. Each question presents the gate's identity + context + the
three routing options.

**Large pipelines (>3 manual jobs):** batch into a single
`AskUserQuestion` with `multiSelect: true` — the options are the job
names, selected = FIRE, unselected = LEAVE PENDING. Then a follow-up
`AskUserQuestion` (single-select) for anything the operator wants to
explicitly SKIP (cancel).

### Per-gate question shape

Route: FIRE / SKIP / DEFER — three mutually exclusive options.

```text
question: "Manual job `deploy-staging` (stage: deploy, environment: staging) — what should I do?"
header:   "deploy-staging"
options:
  - label: "Fire it now (recommended)"
    description: "POST /jobs/<jid>/play — pipeline resumes, downstream jobs run."
  - label: "Leave pending"
    description: "Don't act on it — it stays available for a human to fire later. Pipeline stays blocked."
  - label: "Cancel it"
    description: "POST /jobs/<jid>/cancel — the gate is dismissed; pipeline continues past it if allow_failure=true, otherwise fails."
```

The label of the "Fire" option depends on the gate's identity — for
prod deploys, do NOT mark FIRE as (Recommended) unless the operator
context already established it's the intended action.

### Batch question shape (>3 gates)

```text
question: "Which manual jobs should I FIRE? Unselected jobs stay pending."
header:   "Fire which gates"
multiSelect: true
options: <one label per manual job, description = "stage/env">
```

Follow up on any explicit SKIP with a second single-select. Never
cancel a gate implicitly — cancels affect pipeline state and should
be an explicit choice.

## The action — fire selected, cancel skipped

```bash
# For each JID marked FIRE:
glab api --method POST "projects/$PROJ/jobs/$JID/play" >/dev/null

# For each JID marked SKIP (cancel):
glab api --method POST "projects/$PROJ/jobs/$JID/cancel" >/dev/null

# DEFER = do nothing.
```

Verify each action landed by re-reading the job status; a fired job
transitions to `pending` → `running` within ~5 s.

## Reporting shape

Output one line per gate, aligned:

```text
manual-triage pipeline=$PID
  deploy-staging   [deploy, staging]   FIRED   → job 8123456 pending
  release-prod     [deploy, prod]      DEFERRED
  legacy-notify    [notify, -]         CANCELED
```

Fold each decision into a `bd note` on the current bead (if one is
claimed) so future wakes can see the human's routing choice.

## Handoff back to the poller

After firing, hand back to whichever caller invoked this skill:

- Called from **`glab-push-flow`** or **`async-wait §4a`**: return
  control; the caller re-arms `glab_ci_wait_failfast.sh` — the newly
  fired jobs will now show up as `pending` / `running`, unblocking
  the poll.
- Called from **`glab-mr-ready`**: re-run the readiness probe; the
  pipeline row should transition from `manual (waiting on gate)` to
  `running (X/Y jobs done)`.

## Gotchas

- **`glab ci run --job <name>`** exists but re-runs a whole
  pipeline with only that job; NOT what you want. Use `glab api POST
  /jobs/:jid/play` — that fires the existing manual job in-place.
- **Job name collisions across stages** — GitLab allows the same
  `name` in different stages of a matrix pipeline. Always route by
  job `id`, not `name`.
- **`allow_failure=true` manual jobs** — cancelling them lets the
  pipeline proceed; cancelling a non-allow_failure manual job makes
  the pipeline `failed`. The `--cancel` option must reflect this
  (label the SKIP option accordingly per gate).
- **Bridge jobs (child pipelines)** — a manual job that triggers a
  child pipeline (`trigger:` in `.gitlab-ci.yml`) will spawn a new
  pipeline id on FIRE; the caller should re-scope its poll to the
  child pipeline id if downstream logic depends on it.
- **`environment` field is nested** — `.environment.name`, not
  `.environment` (which is an object). Older glab / API responses
  omit the field entirely for jobs without environments — the jq
  above handles that with `// ""`.

## Skipping / non-default

- Fully-non-interactive contexts (headless CI, batch bd runs): if
  `AskUserQuestion` is not available, log the manual jobs to
  stdout + `bd note` and exit code `2` (deferred). Do NOT auto-fire.
- Operator passed `--fire-all` to the caller: fire every manual job
  without asking. Log why in a `bd note`.

## Composes with

- **glab-push-flow** — the post-push orchestrator invokes this on
  the poller's exit code 5 (MANUAL_BLOCKED).
- **async-wait §4a** — the fail-fast poller's exit code 5 hands
  the pipeline id here.
- **glab-mr-ready** — the "Pipeline manual" row of the readiness
  report delegates here.
- **glab-mr-automerge** — a pipeline blocked on manual jobs will
  never satisfy MWPS; fire the gates here first, then arm.
- **beads** — record each routing decision as a `bd note` so future
  sessions can see the human's call without re-asking.
