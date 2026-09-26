---
name: glab-mr-automerge
description: Arm Merge-When-Pipeline-Succeeds (MWPS / auto-merge) on a GitLab MR. Atomic — takes an MR IID (or the MR associated with the current branch), calls `glab mr merge --when-pipeline-succeeds` with the project's merge strategy, then verifies `merge_when_pipeline_succeeds=true` came back green. Refuses to arm on a still-draft MR unless `--keep-draft` is passed (draft MRs never merge, so arming MWPS is a silent no-op). Trigger on "arm auto-merge", "set auto-merge", "auto-merge on !123", "MWPS", "merge when pipeline succeeds", "merge on green", "auto merge after push", "enable automerge for this MR", or the standing rule "whenever an MR is pushed / created / rebased, arm auto-merge". Composes under `glab-push-flow` (the post-push orchestrator) and is a mandatory next step for `glab-mr-open`.
---

# glab-mr-automerge — arm MWPS, verify it stuck

`glab mr create` returning 201 does not arm auto-merge. `glab mr
merge --when-pipeline-succeeds` does — but only if the MR is (a) not
draft, (b) has a running or successful pipeline, (c) has no
unresolved blocking discussions, and (d) the caller has merge
permission. This skill wraps those preconditions so the operator's
"push and it'll auto-merge" mental model actually holds.

## Prerequisites

- `glab auth status` OK on the target host (self-hosted:
  `GITLAB_HOST=$GITLAB_HOST`).
- An MR IID (or the MR associated with the current branch — the
  recipe below auto-resolves it).
- The MR is **not draft** (glab silently no-ops MWPS on drafts).

## Non-negotiables

- **Never call `glab mr merge` without `--when-pipeline-succeeds`** —
  bare `glab mr merge` merges NOW, ignoring CI. Wrong tool.
- **Never arm on a draft** unless the operator explicitly passed
  `--keep-draft`. Default: refuse and print the fix (`glab mr update
  <IID> --ready` first).
- **Match the project merge strategy** — read `merge_method` from
  `projects/:id` (`merge`, `rebase_merge`, `ff`) and pass the
  corresponding flags: `--squash` if the project prefers squash,
  `--remove-source-branch` unless the operator opts out.
- **Verify** — MWPS silently fails on permission-denied. Re-read the
  MR and confirm `merge_when_pipeline_succeeds=true` before reporting
  success.

## The safe recipe

```bash
export GITLAB_HOST=<self-hosted-host-if-any>
IID="${1:-$(glab mr view --output json 2>/dev/null | jq -r '.iid // empty')}"
[ -z "$IID" ] && { echo "no MR IID and no MR for current branch" >&2; exit 1; }

MR=$(glab mr view "$IID" --output json)
DRAFT=$(jq -r '.draft // .work_in_progress // false' <<<"$MR")
STATE=$(jq -r '.state' <<<"$MR")

case "$STATE" in
  merged|closed) echo "MR !$IID is $STATE — nothing to arm"; exit 0 ;;
esac

if [ "$DRAFT" = "true" ] && [ "${KEEP_DRAFT:-0}" != "1" ]; then
  echo "MR !$IID is draft — MWPS is a no-op on drafts." >&2
  echo "Fix: glab mr update $IID --ready   (then re-run)" >&2
  echo "     or export KEEP_DRAFT=1 to arm anyway (will only fire once un-drafted)" >&2
  exit 2
fi

# Project merge strategy — squash policy is a project setting
PROJ=$(jq -r '.project_id' <<<"$MR")
STRAT=$(glab api "projects/$PROJ" | jq -r '.merge_method')
SQUASH_OPT=$(glab api "projects/$PROJ" | jq -r '.squash_option // "default_off"')

FLAGS=(--when-pipeline-succeeds --remove-source-branch)
case "$SQUASH_OPT" in
  always|default_on) FLAGS+=(--squash) ;;
esac

glab mr merge "$IID" "${FLAGS[@]}"

# Verify — MWPS silently fails on permission-denied
sleep 2
ARMED=$(glab mr view "$IID" --output json | jq -r '.merge_when_pipeline_succeeds // false')
if [ "$ARMED" != "true" ]; then
  echo "FAIL: MWPS did not arm on !$IID — check merge permission on project $PROJ" >&2
  exit 3
fi
echo "MWPS armed on !$IID (strategy=$STRAT squash=$SQUASH_OPT)"
```

## Exit codes

- `0` — MWPS armed OR MR already merged/closed
- `1` — no MR IID resolvable (bad branch / no MR for branch)
- `2` — MR is draft and operator did not pass `KEEP_DRAFT=1`
- `3` — glab returned OK but verification shows MWPS not armed
  (permission problem — surface the project id in stderr)

## Draft handling — the `--keep-draft` escape

If the operator wants MWPS pre-armed so that un-drafting the MR
later immediately arms it, pass `KEEP_DRAFT=1`. Use sparingly:
without a follow-up un-draft, the MR sits with MWPS armed forever,
which humans read as "someone forgot about this MR".

## Common failure modes

- **Pipeline hasn't started yet** (`head_pipeline: null` right after
  push) — glab returns "no pipeline running". Retry after ~10 s, or
  let `glab-push-flow` sequence the arm after ci-watch detects the
  pipeline id.
- **Blocking discussion open** — GitLab refuses MWPS. `glab-mr-ready`
  covers the discussion-resolution loop; run it first if the report
  shows `Blocking threads: N`.
- **Approvals not yet met** — some projects require approvals BEFORE
  MWPS can arm. Same fix: `glab-mr-ready` shows the missing
  approvers; ping them, then re-arm.
- **Pipeline blocked on manual jobs** — arming MWPS on a pipeline
  waiting for a manual gate will hang forever. `glab-push-flow`
  detects this and delegates to `glab-ci-manual-triage` first;
  re-arm after the gates are fired.

## Skipping / non-default

- `--no-automerge` (upstream): the operator explicitly does not want
  auto-merge (e.g. this MR is a "release the day of" cut and merging
  on green would beat the release plan). Do not arm; log why.
- `KEEP_DRAFT=1`: arm on draft anyway. See caveat above.

## Composes with

- **glab-mr-open** — arms MWPS immediately after MR creation
  (mandatory next step).
- **glab-push-flow** — the post-push orchestrator that decides
  WHEN to call this skill (after push / after re-push / after a
  ci-watch resume).
- **glab-mr-ready** — must be green (or explicitly ignored) before
  arming; if unresolved threads or missing approvals, run readiness
  first.
- **glab-ci-manual-triage** — pipelines blocked on manual gates
  never satisfy MWPS; the triage skill fires the gates first.
- **async-wait §4a** — after MWPS is armed, the fail-fast poller
  observes the terminal state and either lets MWPS merge, or
  intercepts on failure and un-arms silently (MWPS auto-disarms on
  pipeline failure — no action needed).
