---
name: jira-deploy
description: Orchestrate an env-by-env deploy of the merged fix — dev → verify → staging → verify → prod (manual gate) → verify. Discovers the repo's deploy mechanism (Spinak manual pipeline job / Argo CD sync / GitLab environment / Terraform apply per env) via `.gitlab-ci.yml` job names + `.gitlab/environments/`. Delegates each verify phase to `jira-monitor` (pup / kubectl / aws / dig menu). Never auto-fires the prod deploy — that bead is `blocking:human`. Trigger on "deploy the fix", "roll out dev/staging/prod", "deploy env by env", "ship it env by env", "next env", "promote to staging", "promote to prod". The `phase:deploy` steps of the support-ticket bead DAG.
---

# jira-deploy — dev → staging → prod, gated per env

**DOR/DOD gates:** see `jira-ticket/references/dor-dod.md` §
`phase:deploy env:<env>` and `phase:verify env:<env>`. DOR blocks
prod-deploy until `blocking:human` is dropped by the operator; DOD
requires `deploy.md` to record env, timestamp, pipeline URL, deploy
method, AND the exact rollback command (rollback is only credible
if written down at deploy time, not invented later).

The rollout phase. Fires the deploy for one env, waits for it to
land, delegates verification to `jira-monitor`, and only advances to
the next env when verify is green.

## When to reach for it

- `phase:merge` closed (fix is on master / release tag exists).
- `bd ready` surfaces a `phase:deploy env:<env>` bead.
- User says "deploy dev", "promote to staging", "roll to prod".

## Prerequisites

- Read `jira-monitor` — the verification menu called after each env.
- Read `glab` (`glab ci run <job-id>` for manual jobs; `glab ci
  view` for pipeline TUI).
- Read `explicit-cluster-context` — Argo / kubectl invocations MUST
  pass `--context <env>` explicitly.

## Step 1 — Discover the deploy mechanism

Not every repo deploys the same way. Detect from artifacts, in
priority order:

| Signal | Mechanism |
| --- | --- |
| `.gitlab-ci.yml` has jobs matching `^deploy-(int\|stg\|prd\|dev\|staging\|prod)` with `when: manual` | Spinak / GitLab manual job — trigger via `glab ci run <job-id>` |
| `.gitlab-ci.yml` uses `environment:` blocks | GitLab Environments — deploy via merge to a specific ref OR `glab api projects/.../environments/<id>/stop` etc. |
| `argocd/` folder or `Application` YAML at repo root | Argo CD — `argocd app sync <app>-<env>` or `kubectl` on the Application CR |
| `helm/` folder + `values-<env>.yaml` | Helm — deploy via CI job (rare to fire manually) |
| Terraform stack (`.tf` files at root, no CI deploy job) | Merge = apply; nothing to trigger manually. Verify only |

Emit a "deploy plan" for the ticket into `$ticket_dir/deploy.md`
listing: mechanism, exact command per env, expected duration,
rollback command.

```bash
# Example probe against a Spinak-style .gitlab-ci.yml:
glab api "projects/$PROJ_ID/pipelines/$LATEST_PIPE_ID/jobs" \
  | jq -r '.[] | select(.name | test("^deploy-")) |
           "\(.status)\t\(.name)\t(id=\(.id))"'
```

## Step 2 — Fire the deploy for the current env

Trigger the exact command from the deploy plan. Do NOT wing it.

**Spinak / GitLab manual job**:

```bash
# Find the manual job on the merge pipeline
JOB_ID=$(glab api "projects/$PROJ_ID/pipelines/$MERGE_PIPE_ID/jobs" \
  | jq -r ".[] | select(.name == \"deploy-$ENV\" and .status == \"manual\") | .id")

# Fire it
glab api "projects/$PROJ_ID/jobs/$JOB_ID/play" -X POST

# Watch it live in a herdr split — delegate to ci-watch
```

**Argo CD sync**:

```bash
argocd app sync "<app>-$ENV" --grpc-web
# Wait for Synced + Healthy
argocd app wait "<app>-$ENV" --health --sync --timeout 900
```

**Terraform (merge already applied)**: skip trigger, go to verify.

## Step 3 — Watch the deploy — foreground pane AND async wake-back

Two channels, both cheap, both non-blocking:

- **Foreground (human)** — pair with **ci-watch** (Spinak / GitLab)
  OR **k8s-watch** (Argo / Helm). The split auto-closes on terminal
  state, gives the operator live progress.

- **Background (Claude wakes on completion)** — arm **async-wait**
  before the turn ends so the pipeline / rollout wakes you WITHOUT
  the operator having to say "check now". Use the `watch:` bead-tag
  convention:

  ```bash
  # Deploy fired via glab manual job — pipeline id is on the merge
  # pipeline. Anchor on the deploy-<env> bead so the wake reconstructs
  # state via `bd show`.
  PIPELINE_ID=$(glab api "projects/$PROJ_ID/pipelines/$MERGE_PIPE_ID" \
    | jq -r .id)
  bd note "$deploy_bead" "async-wait armed: watch:pipeline=$PIPELINE_ID \
env=$ENV @ $(date -Iseconds). On wake: run verify-$ENV bead."
  # Delegate the wait shape to async-wait (recipe 4a) — Bash bg for
  # jobs likely < 10 min, ScheduleWakeup 1200s fallback otherwise.
  ```

  For Argo / kubectl rollouts, use async-wait recipe 4c
  (`kubectl rollout status --timeout=30m` in `Bash run_in_background`
  — exit 0 on success, non-zero on timeout/failure; harness delivers
  the completion notification).

Never synchronously block the loop on a deploy. The operator will
run out of session time before the deploy finishes.

## Step 4 — Verify (delegate to jira-monitor)

`jira-monitor` owns the menu: pup (Datadog logs / metrics /
monitors), kubectl (pod health / recent restarts / events), aws
(resource state), dig (DNS), custom (curl a health endpoint).

Which subset applies is ticket-dependent — the operator's
`fix.md § Verification plan` names them; `jira-monitor` runs each
and rolls up a green/yellow/red per env.

```bash
# Dispatched by beads-flow via the verify-<env> bead
jira-monitor check --env "$ENV" --ticket "$TICKET" \
  --plan-file "$ticket_dir/fix.md"
```

Close the `verify:<env>` bead only on green (or explicit operator
OK on yellow — never on red).

## Step 5 — Advance to next env — or stop

DAG ordering (from `beads-decompose`):

- `verify-dev` green → `bd ready` surfaces `deploy-staging`.
- `verify-staging` green → `bd ready` surfaces `deploy-prod`, BUT
  it carries `blocking:human` — `beads-flow` PAUSES.
- Operator says "go" → drop `blocking:human`, `beads-flow` resumes.

## Prod is always a manual gate

Regardless of how green dev + staging looked:

```text
Ready to deploy to PROD:
  Repo:         $REPO
  Fix commit:   $SHA  (merged !$IID)
  Dev verify:   green (see verify-dev.md)
  Staging verify: green (see verify-staging.md)
  Rollback:     <exact command / MR / helm rollback>
  Blast radius: <one line from fix.md>

Confirm? Type 'deploy prod' to proceed.
```

`beads-flow` will NOT auto-run this bead — `blocking:human` label
enforces the pause.

## Anti-patterns

- **Auto-firing prod without operator OK** — hard rule. Even if
  verify-staging is green, even if the DAG has no other work.
- **Skipping envs to save time** — if the pipeline has dev + stg +
  prd, use all three. Prod is not the first env you learn about a
  regression on.
- **Ignoring the verify step** — deploying without confirming
  verify-green defeats the whole DAG. If `jira-monitor` returns
  red or yellow, stop.
- **Doing a manual `kubectl apply` bypassing the CI deploy** — the
  next redeploy from CI will revert your manual change silently.
  Use the deploy pipeline.
- **Firing the deploy job without recording the command in
  `deploy.md`** — a future operator (or you tomorrow) needs the
  exact invocation for rollback.

## Composes with

- **jira-monitor** — the per-env verification skill.
- **jira-merge** — the phase that produced the merge commit.
- **glab** — `glab ci run <job-id>`, `glab api .../jobs/<id>/play`.
- **ci-watch / k8s-watch** — live pane for the deploy in progress
  (foreground, for the operator).
- **async-wait** — the background counterpart; arms a wake-back on
  the deploy pipeline / rollout so Claude resumes when it lands,
  without the operator prompting (see `watch:pipeline=<id>` and
  `watch:rollout=<ns/deploy>` conventions).
- **explicit-cluster-context** — mandatory for Argo / kubectl.
- **beads-flow** — dispatches this on `phase:deploy env:<env>`
  beads; respects the `blocking:human` gate on `env:prod`.
