---
name: glab-push-flow
description: The always-on post-push GitLab lifecycle orchestrator. After ANY `git push`, `glab mr create`, `glab mr rebase`, or `glab ci retry` on a branch tracked by GitLab CI, this skill runs the full lifecycle in one call — detects the MR (if any), arms MWPS via `glab-mr-automerge`, opens the `ci-watch` herdr split for the human, kicks off the fail-fast poller via `async-wait §4a` in the background, and on `MANUAL_BLOCKED` (exit code 5) delegates to `glab-ci-manual-triage` to ask which manual gates to fire — then re-arms the poller. Composes atomic skills instead of duplicating them. Trigger UNCONDITIONALLY on "git push", "just pushed", "pushed to <branch>", "push and create MR", "opened an MR", "created a new MR", "MR is up", "push the branch", "new pipeline started", "CI is running", "arm the flow", "check my pipeline", "am I merging on green". Use this INSTEAD of manually chaining ci-watch + async-wait + automerge — the composition is the point.
---

# glab-push-flow — one call, whole post-push lifecycle

You just pushed. Six things should happen automatically:

1. Is there an MR on this branch? If not, offer to create one (see
   `glab-mr-open`) — but don't force it.
2. If there is an MR and it's not draft: arm MWPS.
3. Open `glab ci view` in a herdr split so the human can watch.
4. Poll the pipeline fail-fast in the background so Claude wakes on
   the FIRST job failure, not the pipeline-level terminal state.
5. On pipeline blocked by manual jobs: ask the human which gates to
   fire.
6. On failure: fold into the current bead + `PushNotification`.
7. On success: MWPS merges the MR automatically (no action needed).

This skill is the composer that runs those steps in order. Every
step delegates to an atomic skill — do not re-implement them here.

## Prerequisites

- `glab auth status` OK on the target host.
- Current branch is pushed (`git push` completed).
- The branch has a `.gitlab-ci.yml` (or an included template that
  produces a pipeline). No pipeline → step 3+ silently skip.
- A bead is claimed (or the caller creates one) — this skill anchors
  its wake-back state on a bead per `async-wait` conventions.

## The orchestration — steps in order

### Step 1 — resolve context

```bash
export GITLAB_HOST=<self-hosted-host-if-any>
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# MR on this branch? empty JSON if none.
MR_JSON=$(glab mr view --output json 2>/dev/null || echo '{}')
MR_IID=$(jq -r '.iid // empty'  <<<"$MR_JSON")
MR_DRAFT=$(jq -r '.draft // .work_in_progress // false' <<<"$MR_JSON")

# Latest pipeline on this branch.
PIPE_JSON=$(glab ci status -b "$BRANCH" -F json 2>/dev/null || echo '{}')
PIPE_ID=$(jq -r '.id // empty' <<<"$PIPE_JSON")
PIPE_STATUS=$(jq -r '.status // "none"' <<<"$PIPE_JSON")
```

If `PIPE_ID` is empty, the push has not triggered a pipeline yet.
Sleep 10s and retry once; still empty → branch has no CI, exit
gracefully (nothing to poll).

### Step 2 — arm MWPS if there's an MR

Delegate to **`glab-mr-automerge`** — do not inline the merge call.

```bash
if [ -n "$MR_IID" ]; then
  if [ "$MR_DRAFT" = "true" ]; then
    echo "MR !$MR_IID is draft — skipping MWPS arm (see glab-mr-automerge for KEEP_DRAFT escape)."
  else
    # This calls the glab-mr-automerge skill's recipe.
    glab-mr-automerge "$MR_IID" || {
      code=$?
      case $code in
        2) echo "!$MR_IID still draft — will re-arm after un-draft" ;;
        3) echo "MWPS arm failed on !$MR_IID — permission?" >&2 ;;
        *) echo "MWPS arm returned $code on !$MR_IID" >&2 ;;
      esac
    }
  fi
fi
```

If the operator explicitly passed `--no-automerge`, log the skip and
move on. This is a valid escape (e.g. release-day MRs).

### Step 3 — open the ci-watch split (human visibility)

Delegate to **`ci-watch`** — do not inline `herdr-tui launch` here.
The `ci-watch` recipe handles labelling, dedup via `herdr-find`, and
auto-close on terminal state (including the new `manual` case — see
that skill's update).

### Step 4 — kick off the fail-fast poller (background)

The scratch helper `glab_ci_wait_failfast.sh` opens its OWN
`ci-watch` split (deduped against step 3) and short-circuits on the
first non-`allow_failure` failed job, on success, on cancel, on
timeout, OR on `MANUAL_BLOCKED` (exit 5 — added by this skill's
sibling change). Run it in `Bash run_in_background: true` per
`async-wait §4a`:

```bash
BEAD=$(bd ready --json | jq -r '.[0].id // empty')
[ -n "$BEAD" ] && {
  bd update "$BEAD" --claim
  bd note "$BEAD" "watch:pipeline=$PIPE_ID mr=${MR_IID:-none} armed=$(date -Iseconds)"
}

# background — harness notifies on exit; exit code drives the next step.
bash "$HOME/.cache/claude/scratch/glab_ci_wait_failfast.sh" "$PIPE_ID"
```

### Step 5 — route the poller's exit code

| Exit | Meaning | Next step |
| --- | --- | --- |
| `0` | Pipeline succeeded | If MWPS armed: MR merges automatically. Close the bead. |
| `1` | A job failed | Read the fail-fast stdout stanza; `bd note` the job; `PushNotification "!<IID> failed on job <name>"`; fold into a fix (see `mm-skills-structured-root-cause-analysis` if the failure is non-obvious). |
| `2` | Pipeline canceled/skipped | `bd note` + report. No further action unless operator asks. |
| `3` | Timeout (1h) | Re-schedule via `ScheduleWakeup delaySeconds=1800` with the same wake-prompt. |
| `4` | Args / auth error | Surface to operator — usually a `GITLAB_HOST` mismatch or `glab auth` expired. |
| `5` | **MANUAL_BLOCKED** — every non-manual job done, one or more manual jobs pending | **Delegate to `glab-ci-manual-triage`**. After the human's routing, re-invoke `glab_ci_wait_failfast.sh "$PIPE_ID"` — the newly fired jobs restart the poll loop. |

### Step 6 — re-arm loop for MANUAL_BLOCKED

```text
Loop:
  run glab_ci_wait_failfast.sh $PIPE_ID
  exit=$?
  if exit==5:
    parse MANUAL_BLOCKED jobs=[…] stanza
    invoke glab-ci-manual-triage $PIPE_ID
    goto Loop
  else:
    route per table above; exit
```

Cap the loop at 3 iterations — if the pipeline keeps producing new
manual gates, something is off; escalate to the operator with
`PushNotification "pipeline $PIPE_ID has cascading manual gates; review"`.

## When NOT to run this skill

- **Docs-only pushes with no CI** — `glab ci status` returns nothing;
  the whole flow no-ops.
- **Draft-only worktrees** — some operators push scratch branches
  they never intend to open MRs on. Detection: no MR + branch name
  matches `^(scratch|wip|tmp)/`. In that case do NOT auto-create an
  MR; just log "no MR, no MR wanted".
- **Non-interactive / batch runs** — `AskUserQuestion` (used by
  `glab-ci-manual-triage` in step 5) needs an operator. Fall back
  to `bd note` + exit; a human resumes later.
- **The operator explicitly said "just push, don't watch"** — respect
  that; do not spawn the ci-watch split.

## Skipping individual steps

The flow accepts these environment overrides:

- `PUSH_FLOW_NO_AUTOMERGE=1` — skip step 2 (MWPS arm).
- `PUSH_FLOW_NO_TUI=1` — skip step 3 (`ci-watch` split); also
  passed to the scratch poller as `--no-tui`.
- `PUSH_FLOW_NO_POLL=1` — skip steps 4-6 (background poll). Use for
  "I'll watch it myself".
- `PUSH_FLOW_FIRE_ALL=1` — on `MANUAL_BLOCKED`, fire every manual
  job without asking. Cascades to `glab-ci-manual-triage`.

## Composes with — the whole point

This skill exists to compose these atomic skills; do not inline
their logic here. If a step needs to change, change the atomic
skill.

- **glab-mr-open** — creates the MR (step 0, if the caller pushed
  first-time and wants an MR). `glab-mr-open` itself invokes
  `glab-push-flow` as its mandatory next step — the composition is
  bidirectional.
- **glab-mr-automerge** — step 2.
- **ci-watch** — step 3 (foreground split for the human).
- **async-wait §4a** — steps 4-6 (background poll + wake-back on
  exit code).
- **glab-ci-manual-triage** — step 5 branch on exit 5.
- **glab-mr-ready** — invoked after step 5 success if the operator
  asks "is my MR ready for review".
- **beads** — the wake-back anchor across every step.
- **scratch-scripts / glab_ci_wait_failfast.sh** — the fail-fast
  poller with `MANUAL_BLOCKED` detection (exit 5).
