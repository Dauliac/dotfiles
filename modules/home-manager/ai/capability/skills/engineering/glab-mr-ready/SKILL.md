---
name: glab-mr-ready
description: Structured MR readiness gate — read pipeline status, approval rules, blocking discussions, conflicts, assigned reviewers, title cleanliness; emit a fixed-shape readiness report; act on any red row (missing reviewer → add via `glab-mr-assign`, dirty title → clean via `glab-mr-title`, pipeline failed → `glab job log` + fold into fix.md). Refuses to declare "ready for review" until every row is green. Trigger on "is the MR ready", "check MR pipeline", "MR readiness", "prepare for review", "before I un-draft", "did that MR pass CI", "review readiness of !123". Complements `mm-skills-gitlab-mr` (its `prepare-for-review.md` reference) with the concrete probes and the fixed report shape.
---

# glab-mr-ready — the readiness gate

`glab mr create` returning 201 is NOT "ready for review". An MR is
ready only when EVERY row below has a concrete answer AND all reds
have been acted on. Never emit "opened, over to you" without this.

## Prerequisites

- `glab auth status` OK on the target host.
- MR IID + `--repo <group/project>` (or run from inside the repo).

## The probe — three glab calls, one report

```bash
export GITLAB_HOST=<self-hosted-host-if-any>
REPO=<group/subgroup/project>
IID=<mr-iid>
PROJ_ID=$(glab api "projects/$(printf '%s' "$REPO" | jq -sRr @uri)" | jq -r .id)

# 1. MR header — state / draft / conflicts / discussions / reviewers /
#    head_pipeline pointer
MR=$(glab mr view "$IID" --repo "$REPO" --output json)

# 2. Approval rules — WHO must approve, HOW MANY, IS IT MET
APPROVAL=$(glab api "projects/$PROJ_ID/merge_requests/$IID/approval_state")

# 3. Pipeline jobs — status per stage
PIPE_ID=$(printf '%s' "$MR" | jq -r '.head_pipeline.id // empty')
JOBS=$([ -n "$PIPE_ID" ] && glab api "projects/$PROJ_ID/pipelines/$PIPE_ID/jobs" || echo '[]')
```

## The report — fixed shape, one field per line

```text
MR !$IID — <title>
  URL:                <mr.web_url>
  Title clean:        yes | NO (contains 'Draft: Draft:' — fix via glab-mr-title)
  Draft:              yes | no
  Merge status:       <detailed_merge_status>
                      (mergeable | draft_status | ci_still_running | ci_must_pass |
                       need_rebase | discussions_not_resolved | not_approved)
  Conflicts:          no | YES
  Blocking threads:   0 | N (list of thread URLs)
  Pipeline:           success | running (X/Y jobs done) | failed (job <name>) |
                      manual (waiting on <gate>) | none
  Approvals:          M / N   (missing: <usernames from eligible list>)
  Reviewers assigned: <usernames> | NONE — assign at least 1 from eligible pool
  Assignee:           <username> | NONE — self-assign via glab-mr-assign
  Next action:        <one line — what YOU are about to do to unblock>
```

## The extraction — jq blocks that build each row

```bash
jq_report() {
  jq --argjson jobs "$JOBS" --argjson appr "$APPROVAL" '
    def missing_approvers:
      [ $appr.rules[]? | select(.approved == false and .approvals_required > 0) |
        .eligible_approvers[]?.username ] | unique;
    def pipeline_summary:
      if $jobs == [] then "none"
      else
        ([$jobs[] | select(.status == "success")] | length) as $ok |
        ($jobs | length) as $tot |
        ([$jobs[] | select(.status == "failed")] | first) as $fail |
        ([$jobs[] | select(.status == "manual")] | first) as $man |
        if $fail then "failed (job \($fail.name))"
        elif ($ok == $tot) then "success"
        elif $man and ([$jobs[] | select(.status == "running" or .status == "pending" or .status == "created")] | length) == 0 then "manual (waiting on \($man.name))"
        else "running (\($ok)/\($tot) jobs done)" end
      end;
    def title_clean:
      if .title | test("^Draft:\\s+Draft:") then "NO (double Draft: prefix)"
      elif .title | test("^\\[[A-Z][A-Z0-9]+-[0-9]+\\]") then "yes"
      else "NO (missing [TICKET-ID] prefix)" end;
    {
      iid, title,
      url: .web_url,
      title_clean: title_clean,
      draft: .draft,
      merge_status: .detailed_merge_status,
      conflicts: .has_conflicts,
      blocking_threads: (if .blocking_discussions_resolved then 0 else "N (see MR)" end),
      pipeline: pipeline_summary,
      approvals: ([$appr.rules[]? | select(.approvals_required > 0)] | length | tostring)
                  + " rule(s), missing: " + (missing_approvers | join(",")),
      reviewers: (.reviewers | map(.username) | if length == 0 then ["NONE"] else . end),
      assignees: (.assignees | map(.username) | if length == 0 then ["NONE"] else . end)
    }
  '
}

printf '%s' "$MR" | jq_report
```

## Act on reds — do not just report

For each red row, take the concrete action BEFORE reporting to the
operator. Fold the action's result into the next report iteration.

| Red row | Action |
| --- | --- |
| Title `NO (double Draft:)` | `glab mr update $IID --title "$(printf '%s' "$OLD" \| sed -E 's/^Draft:\s+Draft:\s+/Draft: /')"` — or delegate to `glab-mr-title`. |
| Title `NO (missing [TICKET])` | Delegate to `glab-mr-title` — parses branch, prepends. |
| Assignee `NONE` | `glab mr update $IID --assignee @me`. |
| Reviewers `NONE` | Look up the eligible pool from `approval_state.rules[].eligible_approvers`; pick 1 (git blame on changed files is a decent heuristic); use `glab-mr-assign` to resolve + `+username`-add. |
| Merge status `need_rebase` | `glab mr rebase $IID` (server-side rebase). |
| Merge status `discussions_not_resolved` | Read threads (`glab api projects/$PROJ_ID/merge_requests/$IID/discussions`), address or ask the operator. |
| Pipeline `failed (job X)` | `glab job log <job-id>`; fold failing line into `fix.md § Risks` if in a support-ticket context. |
| Pipeline `running` | Delegate to `ci-watch` (herdr split — foreground for the operator) AND `async-wait` (background wake-back via `watch:pipeline=<id>` bead tag — re-enters `glab-mr-ready` on terminal state, `PushNotification` only if failed). Never block the loop on a long build. |
| Pipeline `manual (waiting on gate)` | Delegate to `glab-ci-manual-triage` — enumerates the pending gates and uses `AskUserQuestion` per gate (FIRE / SKIP / DEFER). After the operator's routing, re-run this readiness probe. |

## When to declare ready

**All green + operator explicit OK** → then and only then:

```bash
glab mr update $IID --ready       # un-draft
# Notify the reviewers by re-adding them (glab pings on --reviewer):
# glab mr update $IID --reviewer "+$USER1,+$USER2"
```

If the ticket is a support ticket, then update Jira via
`twg jira workitem comment create` — see `jira-fix` for the internal-status-ping
convention.

## Gotchas

- `head_pipeline` can be `null` right after `glab mr create` — the
  pipeline is triggered by the push, not the MR. Retry the probe
  after a few seconds; if still null, the branch has no `.gitlab-
  ci.yml` in scope.
- `approval_state` requires you own the project or be an approver;
  self-hosted may return 403 for guests. Fall back to reading
  `.gitlab/CODEOWNERS` locally.
- `blocking_discussions_resolved: true` doesn't mean "no unresolved
  threads" — it means "no BLOCKING threads under project settings".
  Non-blocking threads still exist; read `/discussions` if the
  project uses them for reviewer conversations.
- `detailed_merge_status` is a rich enum in modern GitLab (14.11+);
  older APIs only expose `merge_status: {can_be_merged, cannot_be_merged}`.

## Composes with

- **glab-mr-open** — this skill is the mandatory follow-up to
  creation.
- **glab-mr-automerge** — once every red is green and the operator
  has approved un-drafting, arm MWPS via this skill so `--ready`
  merges on green without further babysitting.
- **glab-ci-manual-triage** — the "Pipeline `manual`" row's action.
- **glab-push-flow** — the post-push orchestrator that invokes this
  readiness gate at the tail end of every push cycle.
- **glab-mr-assign** — the primitive for the "missing reviewer /
  assignee" action.
- **glab-mr-title** — the primitive for the "dirty title" action.
- **ci-watch** — offload pipeline watching to a herdr split.
- **mm-skills-gitlab-mr** — the ManoMano `prepare-for-review.md`
  reference covers the org-specific etiquette; this skill covers
  the probes + the fixed report shape.
- **jira-fix** — step 7 of the support-ticket pipeline delegates
  here.
