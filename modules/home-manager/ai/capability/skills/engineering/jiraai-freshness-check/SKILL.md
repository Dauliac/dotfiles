---
name: jiraai-freshness-check
description: Mandatory pre-post safety gate for every Jira write (comment create, status transition, field update, Done close-out). Take a snapshot of the ticket at DRAFT time (status + last comment id + last comment timestamp + assignee) and, at POST time, diff the live ticket against the snapshot; refuse to post when a new non-me comment landed or the status moved. Prevents the class of bug where a teammate (e.g. Vincent on PLAT-4095) posts a comment that invalidates the ticket while the agent is still drafting the reply  -  the naive `twg jira workitem comment create` would post a stale answer over fresh context. Two atomic sub-commands: `snapshot` (before drafting) and `diff` (before posting). Returns machine-readable verdicts (`OK` / `NEW_COMMENTS` / `STATUS_CHANGE` / `ASSIGNEE_CHANGE` / `BOTH`) that callers key off of. Trigger on "post the reply", "post the comment", "comment on the ticket", "transition to Done", "close the ticket", "update the status", "before I comment on Jira", "is the ticket still current", "did anything new land on PLAT-1234", "recheck the ticket before posting", "freshness check", "am I about to post something stale". Distinct from `jiraai-review` (which is the full ticket summary): this skill is a narrow before/after diff of exactly the fields that would make a pending write outdated. Composes upward with `jira-answer`, `jira-fix`, `jira-review`, `jira-merge`, `jiraai-group`, `async-wait`, `beads`.
---

# jiraai-freshness-check  -  snapshot + diff before every Jira write

**IMPORTANT  -  never post blind.** Jira is multi-writer. Between the
moment the agent starts drafting a reply and the moment it posts, a
teammate can:

- comment with new evidence that invalidates the whole draft
  (real 2026-09 incident: Vincent's comment on PLAT-4095 flipped the
  ticket from "needs investigation" to "invalidated");
- transition the ticket to Done / Won't Do / Duplicate;
- reassign to someone else;
- change the reporter (support-desk merges).

Every one of those moves silently turns a pending `twg jira workitem
comment create` into noise or, worse, misleading noise the reporter
now has to unpick.

This skill is the atomic pre-post gate. Two calls, one contract.

## Contract

- **`snapshot KEY`**  -  writes `$ticket_dir/freshness.json` with the
  minimum fields needed to detect drift.
- **`diff KEY`**  -  re-reads the ticket and compares against the
  snapshot. Prints one verdict token on stdout, exits with a code
  the caller keys off of.

| Verdict | Exit | Meaning | What the caller MUST do |
| --- | --- | --- | --- |
| `OK` | 0 | No drift. Safe to post. | Post. |
| `NEW_COMMENTS` | 10 | ≥1 new non-me comment since snapshot. | Refuse to post; re-read; re-draft; re-snapshot; retry. |
| `STATUS_CHANGE` | 11 | Ticket status differs from snapshot. | Refuse to post; re-evaluate whether the write still makes sense. |
| `ASSIGNEE_CHANGE` | 12 | Assignee differs from snapshot. | Warn the operator; may still post if the write is not ownership-sensitive (an internal status ping is fine; a Done transition is not). |
| `BOTH` | 13 | Multiple drift signals. | Refuse; treat as NEW_COMMENTS + STATUS_CHANGE. |

**Callers MUST NOT proceed on any non-zero exit code without explicit
operator OK.** The whole point of the skill is that agents cannot
override their own freshness verdict silently.

## Prerequisites

- `twg` on PATH with valid OAuth (`twg env`). See `twg-jira`.
- `jq` for JSON diffing.
- A per-ticket work directory the caller owns (e.g. `$ticket_dir`
  from `jira-ticket`). The snapshot file lives there.

## Implementation

Two bash functions the caller sources or copies inline:

```bash
# ---- snapshot: call this BEFORE the human/agent starts drafting ----
freshness_snapshot() {
  local key= dir=
  if [ -z "$key" ] || [ -z "$dir" ]; then
    echo "usage: freshness_snapshot KEY DIR" >&2
    return 2
  fi
  mkdir -p "$dir"

  # One call  -  comments + status + assignee + updated ts. --full is
  # heavier than we need but guarantees comment.comments is present
  # for JSM types (some issue types omit it on plain get).
  local raw
  raw=$(twg jira workitem get "$key" --full -o json | jq '.[0]')

  # Extract just the drift-relevant fields. Field paths handle both
  # flat and nested shapes twg has returned across versions.
  local snap
  snap=$(printf '%s' "$raw" | jq --arg key "$key" '{
    key: $key,
    status:    (.status.name          // .fields.status.name),
    assignee:  (.assignee.accountId   // .fields.assignee.accountId   // null),
    reporter:  (.reporter.accountId   // .fields.reporter.accountId   // null),
    updated:   (.updated              // .fields.updated),
    last_comment_id: (
      ((.comment.comments // .fields.comment.comments // []) | last | .id) // null
    ),
    last_comment_ts: (
      ((.comment.comments // .fields.comment.comments // []) | last | .created) // null
    ),
    snapshot_at: (now | todateiso8601)
  }')

  printf '%s\n' "$snap" > "$dir/freshness.json"
  printf 'snapshot written: %s\n' "$dir/freshness.json" >&2
}

# ---- diff: call this IMMEDIATELY before the write ----
freshness_diff() {
  local key= dir=
  local me="${JIRA_ME_ACCOUNT_ID:-}"     # optional; skips me-owned comments
  if [ -z "$key" ] || [ -z "$dir" ] || [ ! -f "$dir/freshness.json" ]; then
    echo "usage: freshness_diff KEY DIR   (needs $dir/freshness.json)" >&2
    return 2
  fi

  # Fresh pull  -  same shape as snapshot.
  local raw now_snap
  raw=$(twg jira workitem get "$key" --full -o json | jq '.[0]')
  now_snap=$(printf '%s' "$raw" | jq --arg key "$key" --arg me "$me" '{
    key: $key,
    status:    (.status.name          // .fields.status.name),
    assignee:  (.assignee.accountId   // .fields.assignee.accountId   // null),
    reporter:  (.reporter.accountId   // .fields.reporter.accountId   // null),
    updated:   (.updated              // .fields.updated),
    new_non_me_comments: (
      ((.comment.comments // .fields.comment.comments // [])
       | map(select(.author.accountId != $me))
      )
    )
  }')

  local before
  before=$(cat "$dir/freshness.json")

  # Compare.
  local status_before status_now
  status_before=$(printf '%s' "$before"   | jq -r '.status')
  status_now=$(   printf '%s' "$now_snap" | jq -r '.status')

  local assignee_before assignee_now
  assignee_before=$(printf '%s' "$before"   | jq -r '.assignee // "null"')
  assignee_now=$(   printf '%s' "$now_snap" | jq -r '.assignee // "null"')

  local last_id_before
  last_id_before=$(printf '%s' "$before" | jq -r '.last_comment_id // "null"')

  # Any non-me comment with id > snapshot's last id (or created after
  # snapshot's last ts) counts as NEW_COMMENTS. IDs are monotonic
  # strings in Jira, but we cross-check on `created` too.
  local new_count
  new_count=$(printf '%s' "$now_snap" | jq --arg last "$last_id_before" '
    .new_non_me_comments
    | map(select(.id != $last))
    | map(select(($last == "null") or (.id > $last)))
    | length
  ')

  local status_changed=false assignee_changed=false comments_new=false
  [ "$status_before" != "$status_now" ] && status_changed=true
  [ "$assignee_before" != "$assignee_now" ] && assignee_changed=true
  [ "${new_count:-0}" -gt 0 ] && comments_new=true

  # Verdict.
  if $comments_new && $status_changed; then
    echo "BOTH"
    _freshness_report "$key" "$before" "$now_snap" "$new_count" >&2
    return 13
  fi
  if $comments_new; then
    echo "NEW_COMMENTS"
    _freshness_report "$key" "$before" "$now_snap" "$new_count" >&2
    return 10
  fi
  if $status_changed; then
    echo "STATUS_CHANGE"
    _freshness_report "$key" "$before" "$now_snap" "$new_count" >&2
    return 11
  fi
  if $assignee_changed; then
    echo "ASSIGNEE_CHANGE"
    _freshness_report "$key" "$before" "$now_snap" "$new_count" >&2
    return 12
  fi
  echo "OK"
  return 0
}

_freshness_report() {
  local key= before= now= new_count=
  echo "=== freshness drift on $key ==="
  echo "  status:   $(printf '%s' "$before" | jq -r .status) -> $(printf '%s' "$now" | jq -r .status)"
  echo "  assignee: $(printf '%s' "$before" | jq -r '.assignee // " - "') -> $(printf '%s' "$now" | jq -r '.assignee // " - "')"
  echo "  new non-me comments: $new_count"
  if [ "${new_count:-0}" -gt 0 ]; then
    echo "  --- new comment bodies (last 3) ---"
    printf '%s' "$now" | jq -r '.new_non_me_comments[-3:][] |
      "  [\(.created | .[0:16])] \(.author.displayName // "?"): \((.body | tostring)[0:280])"'
  fi
}
```

**Note on `JIRA_ME_ACCOUNT_ID`.** The env var is optional but strongly
recommended  -  otherwise a comment the AGENT just posted (mid-loop, or
in a re-arm) would look like drift and cause a stuck-in-refuse loop.
Callers that already resolve their own accountId (`jira-answer` step 3,
`jira-review`) MUST export it before calling `freshness_diff`. To
resolve once per session:

```bash
JIRA_ME_ACCOUNT_ID=$(twg jira user me -o json | jq -r '.accountId')
export JIRA_ME_ACCOUNT_ID
```

## The PLAT-4095 motivating example

Real 2026-09 incident that motivated this skill:

1. Agent drafted a "here's the fix, could you check please?" reply
   for the reporter on PLAT-4095.
2. Between drafting and posting, Vincent commented on the ticket
   with new evidence that invalidated the whole premise.
3. Agent posted the stale reply anyway. Reporter now had two
   contradictory comments to unpick, and Vincent had to comment
   again to point at his previous message.

With this skill wired in, the sequence becomes:

1. `freshness_snapshot PLAT-4095 $ticket_dir` (before drafting).
2. Draft `answer.md`.
3. On operator "post it"  -  call `freshness_diff PLAT-4095 $ticket_dir`.
4. Verdict: `NEW_COMMENTS` (Vincent's comment). Exit 10.
5. Caller refuses to post; re-runs `jiraai-review` to re-read the
   thread; re-drafts `answer.md`; re-snapshots; retries the diff.

## When to snapshot vs diff

- **Snapshot as early as possible.** For `jira-answer`, snapshot at
  the start of step 1 (Calibrate). For `jira-fix`'s internal status
  ping, snapshot before drafting the ping body. For `jira-merge`'s
  post-merge ping, snapshot before running the merge.
- **Diff as late as possible.** The window between diff and the
  actual write should be milliseconds  -  never `AskUserQuestion`
  between them. Race: operator says "post it" → snapshot ages while
  operator was thinking → diff → post. All three in the same shell
  block, no yield.

## When `NEW_COMMENTS` fires  -  what a caller MUST do

Do NOT just show the diff and ask "post anyway?". That gives the
agent a way to override the safety with a single confirmatory
key-press, defeating the whole gate. Instead:

1. Show the new comment(s) verbatim to the operator.
2. Re-run `jiraai-review` on the ticket.
3. Feed the new comment(s) into the warm Dust conversation (for
   support tickets: `jira-answer` already has `dust_ask` wired up  - 
   ask Dust "given this new comment, does the current draft still
   apply, or does the answer shape change?").
4. Re-draft `answer.md` / `fix.md` / the status ping. Get operator
   OK on the NEW draft.
5. `freshness_snapshot` again (fresh snapshot).
6. `freshness_diff` again  -  must be `OK` before post.

The re-arm loop is bounded: after 3 consecutive `NEW_COMMENTS`
refusals in a single sitting, hand off with `blocking:human` on the
bead  -  the ticket is clearly in a hot conversation and needs the
operator to steer directly.

## When `STATUS_CHANGE` fires

Even more decisive. If the ticket moved to Done / Won't Do /
Duplicate while drafting, the write is almost certainly wrong:

- A `jira-answer` reply on a Done ticket is a reopen-signal noise.
- A `jira-fix` "fix in flight" ping on a Won't Do ticket contradicts
  the resolution.
- A `jira-merge` post-merge ping on a Duplicate ticket is confusing.

Refuse; PushNotification the operator; do NOT auto-retry.

## When `ASSIGNEE_CHANGE` fires

Weakest of the three signals  -  the ticket changing hands does not
necessarily invalidate a status-ping-style comment. The caller
decides:

- **Ownership-sensitive writes** (Done transition, `Waiting for
  customer` transition, capability set)  -  refuse; hand off.
- **Ownership-neutral writes** (internal status ping, MR-ready
  @mention)  -  warn, may proceed on explicit operator OK.

## Testing without posting

```bash
# Snapshot now, wait a bit, diff  -  should be OK.
freshness_snapshot PLAT-4095 /tmp/fc-test
sleep 5
freshness_diff PLAT-4095 /tmp/fc-test   # -> OK, exit 0

# Simulate drift by tampering with the snapshot's status field.
jq '.status = "This ticket was in Backlog"' /tmp/fc-test/freshness.json > /tmp/fc-test/freshness.json.tmp
mv /tmp/fc-test/freshness.json.tmp /tmp/fc-test/freshness.json
freshness_diff PLAT-4095 /tmp/fc-test   # -> STATUS_CHANGE, exit 11
```

## Composes with

- **`twg-jira`**  -  `twg jira workitem get --full` is the read.
- **`jiraai`**  -  shared `twg` cookbook (auth, field shapes); this
  skill's `freshness_snapshot` and `freshness_diff` are the
  posting-safety atoms the cookbook advertises.
- **`jiraai-review`**  -  when `NEW_COMMENTS` fires, callers re-run
  `jiraai-review` to re-read the thread before re-drafting.
- **`jira-answer`**  -  mandatory gate before every reporter-facing
  post AND before the Done transition. Highest-value caller.
- **`jira-fix`**  -  gate before internal status pings.
- **`jira-review`**  -  gate before the @mention "MR ready" ping.
- **`jira-merge`**  -  gate before the post-merge status ping AND
  before the merge itself (a `STATUS_CHANGE` to Won't Do mid-merge
  is a reason to abort the merge).
- **`jiraai-group`**  -  gate the bulk-transition preview: snapshot
  each ticket at preview time, diff at commit time; drop any
  drifted ticket from the batch.
- **`beads`**  -  record the snapshot ts and last diff verdict on the
  bead via `bd note`, so cross-session re-entries know whether the
  draft is still valid.
- **`async-wait`**  -  for `Waiting for customer` re-arm loops
  (`jira-answer` step 11): the wake-back handler MUST call
  `freshness_snapshot` before re-entering the draft loop, and
  `freshness_diff` before its own re-transition write.
