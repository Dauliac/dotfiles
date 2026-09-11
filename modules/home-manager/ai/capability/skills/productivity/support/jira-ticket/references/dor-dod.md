# jira-ticket — DOR / DOD contract per phase

Every phase in the `jira-ticket` pipeline has a **DOR** (definition of ready —
what must be true to *enter* the phase) and a **DOD** (definition of done —
what must be true to *close the bead* for that phase). The orchestrator
refuses to advance if a DOR fails and refuses to close a bead if a DOD fails.

Phase skills consult this doc before mutating state. `phase:close` verifies
its DOR via API calls, not by trusting upstream bead state.

## Universal DOR (all phases)

- `$ticket_dir` exists and contains `ticket.md` (from `jiraai-review`)
- Ticket assignee equals the operator (verify via `jiraai-review` header)
- Ticket status is NOT already `Done` / `Cancelled` (guard against races)
- Dust conversation id is warm (see `$ticket_dir/dust-conversation-id`)

## Universal DOD (all phases)

- The phase's artifact file (`proof.md`, `fix.md`, `deploy.md`, `answer.md`, …)
  exists in `$ticket_dir` and is non-empty
- The bead has a `bd note` referencing the artifact path
- No new `phase:rollback` bead was opened during this phase

## Per-phase gates

### `phase:set-capability`

- **DOR:** ticket `customfield_11907` is empty OR only contains placeholder
  values (`"ALL"`, `"Global"`)
- **DOD:** `customfield_11907` is non-empty AND every value is present in the
  PLAT allowed catalog (see `jiraai/SKILL.md` § PLAT Platform Capability)

### `phase:explore`

- **DOR:** universal DOR only
- **DOD:** `proof.md` contains (a) reproducibility status, (b) root-cause
  hypothesis, (c) `MRs found (via find_mr_urls)` section — even if empty,
  the section MUST be present so future readers know the check was run

### `phase:fix-design`

- **DOR:** `proof.md` exists and includes root-cause hypothesis
- **DOD:** `fix.md` exists AND has an operator OK note
  (`bd note <bead> "operator OK: <yyyy-mm-dd hh:mm>"`)

### `phase:implement`

- **DOR:** `fix.md` OK'd
- **DOD (branch + commits):**
  - Current branch matches `^(feat|fix|chore|refactor|docs|test|ci|perf)/[A-Z][A-Z0-9_]+-[0-9]+-[a-z0-9-]+$`
  - At least one commit on the branch has `[<KEY>]` in the subject
    (`jiraai-commit-check` prepare-commit-msg auto-prepends; the pre-push
    hook refuses to push a compliant branch that lost the prefix)

### `phase:ci-green`

- **DOR:** MR opened via `glab-mr-open` AND `find_mr_urls $KEY` returns
  the new MR URL (proves the remoteLink was written)
- **DOD:** latest pipeline on the MR branch is `success` AND every
  `allow_failure: false` job is `success`

### `phase:review`

- **DOR:** `ci-green` closed AND `glab-mr-ready` last report was green
- **DOD:** `glab mr view $IID --output json | jq` shows
  `upvotes >= project.approvals_required` AND
  `discussion_locked == false` AND all threads resolved

### `phase:merge`

- **DOR:** `phase:review` closed AND `glab-mr-ready` is re-run *now*
  (state drifts between review and merge)
- **DOD:**
  - `glab mr view $IID --output json | jq .state` == `"merged"`
  - `merge_commit_sha` non-null
  - `find_mr_urls $KEY` still returns the MR URL (link survived the merge)

### `phase:tag`

- **DOR:** `phase:merge` closed
- **DOD:** exactly ONE of:
  - New semver tag exists on origin (git-managed release)
  - Skip-close note explains why (`.releaserc` → semantic-release will
    tag; CI-tagged repo; not tag-managed at all)

### `phase:deploy env:<env>`

- **DOR:**
  - `phase:tag` closed (skip-close counts) OR repo has no tag phase
  - For `env == prd`: bead carries `blocking:human` AND operator has
    replied "deploy prod" (drop the label manually)
  - Previous env's `phase:verify` closed green (dev before stg, stg before
    prd) — first env is exempt
- **DOD:**
  - The deploy pipeline job for `<env>` completed with `status == success`
  - `deploy.md` records: env, timestamp, pipeline URL, deploy method,
    exact rollback command

### `phase:verify env:<env>`

- **DOR:** `phase:deploy env:<env>` closed
- **DOD:**
  - `jira-monitor` emits GREEN across the applicable channels
    (pup / kubectl / aws / dig / custom curl — chosen from `fix.md`
    § Verification plan)
  - Post-deploy monitoring window has elapsed (minimum 5 min; longer
    per `fix.md` if the change touches user-visible paths)
  - No new alerts fired during the window (Datadog monitor query
    over the window returns empty)
  - YELLOW requires explicit operator OK note; RED always blocks close

### `phase:answer`

- **DOR:** `phase:verify env:prd` closed green
- **DOD:** `answer.md` exists AND has an operator OK note

### `phase:close` — the terminal gate (verify via API, do NOT trust bead state)

All five must be re-verified programmatically before the ticket is
transitioned to Done:

```bash
close_dor_check() {
  local key=$1 iid=$2 repo=$3 merge_pipeline_id=$4
  local ok=true

  # 1. MR is actually merged
  state=$(glab mr view "$iid" --repo "$repo" --output json | jq -r .state)
  [ "$state" = "merged" ] || { echo "MR $iid state=$state (not merged)" >&2; ok=false; }

  # 2. Merge pipeline succeeded
  status=$(glab api "projects/${repo//\//%2F}/pipelines/$merge_pipeline_id" \
    | jq -r .status)
  [ "$status" = "success" ] || { echo "merge pipeline $merge_pipeline_id status=$status" >&2; ok=false; }

  # 3. Prod deploy job on the merge pipeline succeeded (Spinak / GitLab shape)
  prd=$(glab api "projects/${repo//\//%2F}/pipelines/$merge_pipeline_id/jobs" \
    | jq -r '.[] | select(.name | test("^deploy-(prd|prod|production)$")) | .status' | head -1)
  [ "$prd" = "success" ] || { echo "deploy-prd job status=$prd" >&2; ok=false; }
  # Argo-managed repos: swap the prd check for
  # `argocd app get <app>-prd -o json | jq -r '.status.sync.status,.status.health.status'`
  # → must be Synced + Healthy.

  # 4. Capability set on the ticket
  cap=$(curl -sS -u "$AUTH" "$ROOT/issue/$key?fields=customfield_11907" \
    | jq -r '(.fields.customfield_11907 // []) | length')
  [ "$cap" -gt 0 ] || { echo "ticket $key has no Platform Capability" >&2; ok=false; }

  # 5. No open rollback bead on this ticket
  rb=$(bd list --status open --labels "ticket:$key,phase:rollback" --json 2>/dev/null | jq 'length')
  [ "${rb:-0}" = "0" ] || { echo "$rb open rollback bead(s) on $key" >&2; ok=false; }

  $ok
}
```

- **DOR:** `close_dor_check` returns 0 AND `phase:answer` closed
- **DOD:**
  - Ticket transitioned to Done via `twg jira workitem update --status Done` (twg resolves
    the project-appropriate transition id per issue type)
  - Reply posted via `twg jira workitem comment create --body-format markdown` (the `answer.md` body)
  - Bead note: `closed at <ts>, verified: mr=merged,pipeline=success,deploy-prd=success,capability=<value>`

## Rollback (out of the linear DAG)

If `phase:verify env:<env>` returns RED after deploy, or a Datadog monitor
fires during the post-deploy window, open a `phase:rollback` bead:

- Blocks `phase:close` (see gate 5 above)
- Requires operator OK on rollback plan
- Runs the exact rollback command recorded in `deploy.md`
- On success: re-open `phase:fix-design` with the failure evidence
- On failure: page the operator; do not attempt further rollback loops
