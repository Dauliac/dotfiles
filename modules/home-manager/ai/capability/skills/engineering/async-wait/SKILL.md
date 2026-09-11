---
name: async-wait
description: When you have kicked off a long-running operation (pipeline, k8s rollout, MR discussion, Jira transition, deploy gate, terraform plan, long dust chat, watch flag) and would otherwise block for minutes/hours, sit idle, or hand control back to the user prematurely — use this skill to pick the right async primitive (Bash run_in_background / Monitor / ScheduleWakeup / CronCreate) so Claude waits *for itself*, wakes on completion, records the outcome as a `bd note`, and only pings the user via PushNotification when the outcome is actionable. Reach for it after any of: `git push` to a CI branch, `glab ci run|retry`, `kubectl apply|rollout|create job`, `helm upgrade`, `argocd app sync`, `terraform apply|plan`, opening/updating an MR, transitioning a Jira ticket to a stage that waits on humans, kicking off a Datadog deploy gate, starting a Dust chat with `--async`, or any command a human would say "let me know when it's done" about. Triggers on: "wait for", "poll", "notify me when", "come back to this", "let me know when", "check back", "watch until", "resume when", "block on", "then continue when". Complements the foreground TUI watchers (`ci-watch`, `k8s-watch`, `s3-watch`) — those show the human what's happening live; this skill lets Claude keep the workflow moving without blocking.
---

# async-wait — Claude-side background waits with wake-back and bead handoff

Foreground TUIs (`ci-watch`, `k8s-watch`, `s3-watch`) show the *human* what is
happening in a herdr split. This skill covers the *Claude* side: keep a
long-running operation moving without blocking a tool call for an hour, and
resume the workflow the moment it completes.

Rule of thumb: if the operation is >2 min and has a well-defined terminal
state, do NOT run it in a foreground `Bash` call. Pick a primitive below and
hand control back until the wake.

## 1. Primitive selection

| Signal shape                                            | Primitive                          | Why                                                                 |
| ------------------------------------------------------- | ---------------------------------- | ------------------------------------------------------------------- |
| One completion, known probe, likely <10 min             | `Bash` + `run_in_background: true` | Harness notifies on exit. Zero cache burn. No polling.              |
| One completion, likely >10 min or remote flaky          | `ScheduleWakeup` (1200–1800 s)     | Cheaper than churning `Bash` restarts. Re-check on wake.            |
| Many events, indefinite (log tail, PR comment stream)   | `Monitor` (`persistent: true`)     | One notification per event; you keep working between them.          |
| Many events, until a natural end (per-CI-step reports)  | `Monitor` (bounded)                | Emits per step, exits on final status. Better UX than a single wait. |
| Repeats on a clock (nightly health check, hourly gate)  | `CronCreate`                       | Off-minute (`7 * * * *`, not `0 * * * *`); auto-expires 7 days.     |
| Operation is <2 min and blocking is fine                | Foreground `Bash`                  | Async overhead not worth it.                                        |
| User is actively watching in a split                    | Foreground `Bash` + herdr split    | Human owns the wait. Do not double-poll.                            |

**Avoid ScheduleWakeup at 300 s** — worst of both worlds (pays cache miss with
no amortization). Stay ≤270 s to keep the prompt cache warm, or jump to
≥1200 s for idle waits. Default idle tick: 1200 s.

## 2. The wake-prompt template

`ScheduleWakeup` wake-prompts must be self-contained — they run with a fresh
context window. Anchor to a bead so the wake can reconstruct state.

```text
Resume bead <BEAD_ID>: probe <TARGET> and act on the result.

Steps:
  1. Run: bd show <BEAD_ID> --json | jq .description
  2. Extract the probe command from the "watch:" line.
  3. Execute the probe. Parse its terminal-state field.
  4. If terminal:
       - bd note <BEAD_ID> "<probe-result-summary>"
       - If actionable (failure, awaiting review, gate blocked):
           PushNotification "<one-line action>"
       - Advance the workflow (next bd ready, next skill, next command)
  5. If still running:
       - Re-schedule: ScheduleWakeup delaySeconds=1200 with this same prompt.
```

The `watch:` line convention on a bead's description:

```text
watch:pipeline=12345      → glab ci status -p 12345 -F json | jq -r .status
watch:mr=42               → glab mr view 42 -F json | jq -r '{state, has_conflicts, blocking_discussions_resolved}'
watch:rollout=ns/deploy   → kubectl -n ns rollout status deploy/deploy -w --timeout=1s
watch:jira=KEY-123        → twg jira workitem get KEY-123 --fields status -o json | jq -r '.[0].fields.status.name'
watch:gate=<gate-id>      → dd deployment-gates evaluate <gate-id>
```

## 3. Bead-anchored handoff

Every async wait writes back to the bead it was launched from. This is the
single source of truth — replaces "which skill notified me about what".

```bash
# Launch
BEAD=$(bd ready --json | jq -r '.[0].id')
bd update "$BEAD" --claim
bd note "$BEAD" "async-wait armed: watch:pipeline=$PIPELINE_ID @ $(date -Iseconds)"

# Fire-and-forget shape (Bash run_in_background)
until [ "$(glab ci status -p "$PIPELINE_ID" -F json | jq -r .status)" \
        != "running" ]; do sleep 30; done

# On completion, the wake or exit-notification runs:
bd note "$BEAD" "pipeline $PIPELINE_ID → $STATUS"
[ "$STATUS" = "failed" ] && PushNotification "pipeline $PIPELINE_ID failed on $BRANCH"
```

## 4. Concrete recipes

### 4a. GitLab pipeline — wait for terminal state

**Mandatory pairing:** every active CI poll here MUST also open the
`ci-watch` split (`glab ci view` in a herdr pane, auto-closing on
terminal state) so the human has parallel visibility on what Claude
is waiting for. The recipes below either launch the split themselves
or delegate to the scratch helper that does.

```bash
PIPELINE_ID=$(glab ci status -F json | jq -r .id)
```

**Default — whole-pipeline terminal state.** Use `glab ci status --wait`
(server-side blocking, no local poll loop) inside `Bash run_in_background`,
paired with a `ci-watch` split for the human. Follow the `ci-watch` skill
to launch the split first, then:

```bash
glab ci status -p "$PIPELINE_ID" --wait >/dev/null
s=$(glab ci status -p "$PIPELINE_ID" -F json | jq -r '.status // "unknown"')
echo "TERMINAL=$s"
```

Coverage rule: enumerate every terminal state (`success`, `failed`,
`canceled`, `skipped`) — silence on a crash looks identical to
"still running".

**Fail-fast — return on first non-`allow_failure` failed job.** Whole-pipeline
`failed` only lands after every job in every stage finishes or is skipped;
a job that fails in stage 3 of 15 can otherwise wait 10+ min for a signal
available in ~90 s. Use the scratch helper — it polls
`glab ci get -F json --with-job-details`, short-circuits on the first
non-`allow_failure` failed job, dumps the last 200 log lines, opens
`glab ci trace <jid>` in a follow-up split, and (unless `--no-tui`) opens
the parallel `ci-watch` split at start:

```bash
bash "$HOME/.cache/claude/scratch/glab_ci_wait_failfast.sh" "$PIPELINE_ID"
# exit 0 success | 1 failure (details on stdout) | 2 canceled | 3 timeout
#      | 4 args/auth | 5 MANUAL_BLOCKED (pipeline quiescent, ≥1 manual gate)
```

Wire the exit code into the bead:

- `0` — advance the workflow (next skill / next bead). If MWPS was
  armed via `glab-mr-automerge`, the MR merges by itself.
- `1` — `bd note` the failing job + `PushNotification`. Fold the
  failing line into `fix.md § Risks` if in a support-ticket context.
- `2` — canceled/skipped; report and stop.
- `3` — re-arm with `ScheduleWakeup delaySeconds=1800` and the same
  wake-prompt.
- `4` — surface to operator (usually `GITLAB_HOST` mismatch or
  `glab auth` expired).
- **`5` — MANUAL_BLOCKED**: parse the JSON stanza on stdout and
  delegate to **`glab-ci-manual-triage`** (`AskUserQuestion` per
  gate → FIRE / SKIP / DEFER → glab api POST play/cancel). After
  the operator's routing, **re-invoke** the fail-fast poller — the
  newly fired jobs restart the poll loop. Cap re-invocations at 3
  to catch cascading gates without infinite loops.

The full post-push lifecycle composer that already sequences these
exit codes (open the ci-watch split, arm MWPS if MR exists, run the
poll, route exit 5 → manual-triage → re-poll) is
**`glab-push-flow`** — reach for it instead of hand-rolling the
loop when the async wait is triggered by a `git push`,
`glab mr create`, or `glab ci retry`.

### 4b. GitLab MR — wait for discussions resolved OR new reviewer comment

`Monitor` with a bounded poll. Emit one line per new comment, exit when
`blocking_discussions_resolved=true`.

```bash
MR=$1; prev=""
while :; do
  now=$(glab mr view "$MR" -F json)
  new=$(jq -r --arg prev "$prev" '
    .discussions[]?.notes[]? | select(.created_at > $prev) |
    "\(.author.username): \(.body|.[0:120])"' <<<"$now")
  [ -n "$new" ] && echo "$new"
  prev=$(jq -r '[.discussions[]?.notes[]?.created_at] | max // ""' <<<"$now")
  jq -e '.blocking_discussions_resolved' <<<"$now" >/dev/null && { echo "RESOLVED"; exit 0; }
  sleep 60
done
```

### 4c. Kubernetes rollout — wait for ready

Always pass explicit `--context` and `-n` (see `explicit-cluster-context`).

```bash
kubectl --context="$CTX" -n "$NS" rollout status deploy/"$NAME" --timeout=30m
```

Run in `Bash run_in_background` — the command exits `0` on success, non-zero
on timeout/failure; the harness delivers the completion notification.

### 4d. Jira transition wait (support flow)

Long human-in-loop waits (peer review, product approval) → `ScheduleWakeup`
at 1800 s, probing `twg jira workitem get KEY-XXXX --fields status`. Do NOT `Monitor` —
1-hour poll rate on a UI-driven state does not deserve a persistent process.

### 4e. Datadog deploy gate

Gates evaluate every ~2 min but take up to ~15 min to reach a verdict.
`ScheduleWakeup` at 1200 s; re-schedule until `state ∈ {pass, fail}`.
Cross-reference `datadog-deploy-gate-rollout` for the gate-config side.

## 5. Notification policy

`PushNotification` interrupts the human. Send when:

- **Action required now**: pipeline failed, MR needs a reply, gate blocked
  a deploy, rollout stuck / OOMKilled, Jira transitioned to a state that
  needs their approval.
- **User explicitly asked**: "notify me when X is done".

Do NOT send for:

- Routine success at end of a job the user isn't waiting on.
- Progress ticks (`Monitor` events already handle progress in-chat).
- Anything that finished in <2 min.

One line, <200 chars, lead with the action verb: `"MR !42 needs reply: 2 unresolved review comments from @alice"` not `"MR update"`.

## 6. Cache economics

Each wake past 300 s reloads the conversation past the 5-min cache TTL. Rule:

- **≤270 s wake**: cache warm, cheap. Use for fast-terminal probes (a job you
  believe will finish in <5 min).
- **300 s wake**: forbidden. Pays cache miss with no amortization.
- **≥1200 s wake**: cache miss, but the wait pays for it. Default for idle
  waits.

If you'd naturally pick "5 minutes", drop to 270 s or promote to 1200 s.
Never round-number-minutes your way into the dead zone.

## 7. Skill interop

- Foreground TUI for the human → `ci-watch`, `k8s-watch`, `s3-watch`
- Bead-driven wake-back state machine → this skill
- Notification hygiene → this skill §5
- Terminal-state probes for GitLab → `glab`, `mm-skills-gitlab-mr`
- Cluster / namespace scoping → `explicit-cluster-context`
- Persistent Dust conversation across wakes → `dust` (reuse `--conversationId`)

## 8. Anti-patterns

- **Blocking `Bash` >2 min** when the operation has a probe. Use a primitive above.
- **`Monitor` for a single completion** — never terminates, ties up a slot. Use `Bash run_in_background`.
- **`ScheduleWakeup` at 60 s** for an operation that takes an hour — 60 wake-ups × cache misses. Use 1200 s.
- **`CronCreate` at `0 * * * *`** — fleet-wide top-of-hour spike. Use `7 * * * *`.
- **Notifying on success** for a job the user is not actively waiting on.
- **Polling GitLab CI without a parallel `ci-watch` split** — every active
  poll on a pipeline MUST also open `glab ci view` in a herdr pane so the
  human sees the same state Claude is polling. The scratch helper
  `glab_ci_wait_failfast.sh` handles this by default; only pass `--no-tui`
  in headless / non-interactive contexts.
- **Waiting for whole-pipeline `failed` when a fail-fast probe exists** —
  poll `glab ci get -F json --with-job-details` and short-circuit on the
  first non-`allow_failure` failed job. Recipe: §4a fail-fast.
- **Losing state on wake** — always anchor to a bead; the wake prompt reads
  `bd show <id>` first, no exceptions.
