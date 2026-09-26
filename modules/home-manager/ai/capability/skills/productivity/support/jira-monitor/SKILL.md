---
name: jira-monitor
description: Verification menu for a deployed fix per env — pup (Datadog logs / metrics / monitors), kubectl (pod health / restarts / events), aws (resource state / CloudWatch logs), dig (DNS state for edge/CDN tickets), curl (health endpoints). Runs the subset named in `fix.md § Verification plan`, rolls up per-tool results into a per-env verify file, returns green / yellow / red. Called by `jira-deploy` per env; dispatched by `beads-flow` on `phase:verify env:<env>` beads. Trigger on "verify the deploy", "check the fix landed", "monitor <env>", "did the fix work", "post-deploy check", "is prod happy", "verify staging".
---

# jira-monitor — post-deploy verification menu

Fires the verification tactics the operator picked in
`fix.md § Verification plan` and rolls up a per-env verdict. No
tactic is mandatory across all tickets — a DNS edge ticket verifies
with `dig`, a K8s service verifies with `kubectl` + `pup`, an S3
lifecycle change verifies with `aws s3 ls`.

## When to reach for it

- `jira-deploy` fired the deploy for env X; the `verify-<X>` bead is
  now ready.
- Operator asks "did the fix land?", "verify prod", "monitor
  staging".

## Prerequisites

- Read the tactic skills you'll invoke:
  - **pup** — Datadog CLI (logs / metrics / monitors).
  - **kubectl** — pod / deploy / event state. Always pair with
    `explicit-cluster-context`.
  - **aws** — AWS CLI (resource state / CloudWatch). Always pass
    `--profile <env>` and `--region <r>`.
  - `dig` — plain DNS lookup.
- `fix.md § Verification plan` — names the tactics that apply.
- Env-specific config from `~/.local/share/jiraai/config.yaml`
  (per-env `dd_service` tag, K8s context+namespace, AWS profile+
  region) — populate if empty.

## The verify report — fixed shape, per env

Write to `$ticket_dir/verify-$ENV.md`:

```text
# $TICKET — Verify $ENV — $(date -Iseconds)

## Tactics run
- [ ] pup logs error-rate
- [ ] pup monitors for <service>
- [ ] pup metrics latency
- [ ] kubectl pods + events
- [ ] aws <service>
- [ ] dig public
- [ ] curl health endpoint

## Results

| Tactic | Result | Detail |
| --- | --- | --- |
| pup logs error-rate | GREEN / YELLOW / RED | link + one-line |
| ... | ... | ... |

## Overall
GREEN | YELLOW | RED

## Next
<one line — advance to next env / stop for operator / rollback>
```

## Tactic menu

### 1. Datadog logs — error rate delta

Baseline vs post-deploy window on the same service:

```bash
SERVICE=$(yq -r ".defaults.envs.$ENV.dd_service" ~/.local/share/jiraai/config.yaml)

# Post-deploy window (last 15 min)
post=$(pup logs aggregate --compute=count \
  --query="service:$SERVICE status:error" --from='15m')
# Pre-deploy baseline (15-30 min ago)
pre=$(pup logs aggregate --compute=count \
  --query="service:$SERVICE status:error" --from='30m' --to='15m')

# Green if post ≤ pre * 1.5 (or both under a small floor)
```

### 2. Datadog monitors — anything firing on the service

```bash
pup monitors search --query="service:$SERVICE state:alert" --no-agent
# Any hit → RED. Zero → GREEN.
```

### 3. Datadog metrics — latency / traffic

```bash
pup metrics query \
  --query="p95:trace.http.request.duration{service:$SERVICE}" \
  --from='15m'
# APM durations are NANOSECONDS — see pup skill.
```

### 4. kubectl — pod / deployment health

```bash
CTX=$(yq -r ".defaults.envs.$ENV.kube_context" ~/.local/share/jiraai/config.yaml)
NS=$(yq -r ".defaults.envs.$ENV.kube_namespace" ~/.local/share/jiraai/config.yaml)

kubectl --context "$CTX" -n "$NS" get pods -l "app=$SERVICE" \
  -o custom-columns='NAME:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[0].ready,RESTARTS:.status.containerStatuses[0].restartCount,AGE:.metadata.creationTimestamp'

kubectl --context "$CTX" -n "$NS" rollout status "deploy/$SERVICE"

# Recent events — anything since deploy
kubectl --context "$CTX" -n "$NS" events \
  --for "deployment/$SERVICE" --sort-by='.lastTimestamp' | tail -20
```

Green: all pods `Running`, `Ready`, `RESTARTS` unchanged since
deploy, no `Warning`/`Error` events, `rollout status` returns
`successfully rolled out`.

### 5. AWS — resource state

For a Lambda / S3 / EC2 change:

```bash
PROF=$(yq -r ".defaults.envs.$ENV.aws_profile" ~/.local/share/jiraai/config.yaml)
REG=$(yq -r ".defaults.envs.$ENV.aws_region" ~/.local/share/jiraai/config.yaml)

aws --profile "$PROF" --region "$REG" sts get-caller-identity  # confirm
# then ticket-specific:
aws --profile "$PROF" --region "$REG" lambda get-function --function-name "$FN"
aws --profile "$PROF" --region "$REG" logs filter-log-events \
  --log-group-name "/aws/lambda/$FN" \
  --start-time $(date -d '15 min ago' +%s000) \
  --filter-pattern 'ERROR'
```

### 6. dig — DNS state (edge / CDN tickets)

```bash
# Change expected → NXDOMAIN or new CNAME target?
for HOST in "iframe-legacy-bo.corp.example" "legacy.toolbox.corp.example"; do
  RESULT=$(dig +short "$HOST" @1.1.1.1)
  echo "$HOST  →  ${RESULT:-NXDOMAIN}"
done
```

Green: results match the `fix.md § Verification plan` expectations.

### 7. curl — health endpoint

```bash
URL=$(yq -r ".defaults.envs.$ENV.health_url" ~/.local/share/jiraai/config.yaml)
curl -sS -o /dev/null -w '%{http_code}\n' "$URL"
```

## Rollup rules

- All tactics GREEN → env verify GREEN → close the `verify-<env>`
  bead → `beads-flow` surfaces the next env's deploy.
- Any tactic RED → env verify RED → do NOT close the bead → hand
  off to operator with the failing tactic + suggested next steps
  (retry, rollback, or investigate).
- Any tactic YELLOW (e.g., minor error-rate uptick within noise) →
  env verify YELLOW → operator OK required to advance.

## Baseline-stabilization wait — delegate to async-wait

Metrics right after a deploy are noisy — pod restarts, warm-up
requests, cold caches. A verify run in the first ~5 min will
report FALSE positives (transient errors) or FALSE negatives
(zeroed counters). **Wait for the baseline window before running
the pup / kubectl / aws tactics**:

```bash
# Anchor on the verify bead so the wake reconstructs state.
bd note "$verify_bead" "Deploy on $ENV at $(date -Iseconds). \
async-wait armed: watch:baseline=$ENV wait=1200s. \
On wake: run pup + kubectl + aws tactics."

# Delegate to async-wait — ScheduleWakeup 1200s per §6 cache
# economics (>300s to amortize the cache miss, <3600s to fit in
# one wake).
ScheduleWakeup(
  delaySeconds=1200,
  reason="Datadog error-rate stabilization window on $ENV",
  prompt="Resume verify-$ENV bead — the baseline is stable now. \
Read bd show $verify_bead for tactics + service names, then run \
the pup / kubectl / aws checks and roll up per this skill."
)
# Turn ends. Wake in 20 min runs the actual verify.
```

For dev / staging where the operator wants a fast signal despite
noise, skip the wait and note "smoke-only verify" in the bead.
Prod verify ALWAYS waits — it's the last checkpoint before
`jira-answer` closes the ticket.

## Anti-patterns

- **One-tactic verification** (pup only, or kubectl only) — a fix
  can look green on one tool and be broken on another. Use the
  subset the ticket needs.
- **Comparing post-deploy against `--from='1h'` window that includes
  the deploy** — the numbers get diluted. Use two disjoint windows
  (pre + post), same duration.
- **`pup metrics query` without an aggregation** — see pup skill
  anti-patterns.
- **`kubectl` without `--context`** — mutates shared state; see
  `explicit-cluster-context`.
- **`aws` without `--profile` / `--region`** — see aws skill.
- **Ignoring recent K8s events** — a pod that's `Running` but
  restarting on OOM is a soft red.

## Composes with

- **jira-deploy** — parent phase that calls this per env.
- **pup / kubectl / aws** — the underlying tactics.
- **explicit-cluster-context** — mandatory for kubectl.
- **ci-watch / k8s-watch / s3-watch** — for live views if the
  operator wants to eyeball while verify runs.
- **async-wait** — the baseline-stabilization wait (ScheduleWakeup
  1200s per its §6 cache economics rule); on-wake handler re-enters
  this skill.
- **beads-flow** — dispatches this on `phase:verify env:<env>`
  beads.
