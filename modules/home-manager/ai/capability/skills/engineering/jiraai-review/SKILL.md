---
name: jiraai-review
description: Read-only "brief me on this Jira ticket" — one `twg jira workitem get --full` call returns the issue + comments + remoteLinks + every `customfield_*` present (including JSM Relevant Link `customfield_11380` on PLAT). Wrap with the `find_mr_urls` union from the `jiraai` cookbook to surface every MR mentioned across remoteLinks + JSM Relevant Link + description + comment bodies. Deep mode walks one level of relations (parent + subtasks + issuelinks) via `twg jira workitem bulk-get`. No mutations. Triggers on "review XX-1234", "what's on this ticket", "brief me on XX-9042", "what's the state of", "show me the thread of", "who's talked on this ticket", "what's linked to", "walk me through this ticket".
---

# jiraai-review — one-glance summary of a Jira ticket

Read-only. Pulls everything: header, custom fields, parent chain, children, comment thread, links, and MRs from ALL sources. Never mutates.

**Do not rely on `remoteLinks` alone.** JSM portal-form tickets store the MR URL in `customfield_11380` (Relevant Link) that the Development panel does not surface. Always call `find_mr_urls` from the `jiraai` cookbook — it unions all five hiding spots via `twg jira workitem get --full`.

**Two modes**: `plain` (default — the ticket itself, below) and `deep` (walks one level of relations + collects MRs from every related ticket). Deep is the mode to use at the start of a support ticket, an incident, or whenever you need to feed related-work context into beads or open `ci-watch` on adjacent MRs.

## Prerequisites

- `twg` on PATH with OAuth valid (`twg env`). See `twg-jira`.
- `jq` for JSON walk. `find_mr_urls` is defined in the `jiraai` cookbook.

## One-shot summary (plain)

```bash
KEY="$1"   # e.g. GT-2500

# One call for everything: fields, comments, remoteLinks, every customfield_*.
ISSUE=$(twg jira workitem get "$KEY" --full -o json | jq '.[0]')

echo "=== $KEY ==="
printf '%s\n' "$ISSUE" | jq -r '
  "Title:      \(.summary // .fields.summary)",
  "Type:       \(.issuetype.name // .fields.issuetype.name)",
  "Status:     \(.status.name // .fields.status.name)",
  "Priority:   \(.priority.name // .fields.priority.name // "—")",
  "Assignee:   \(.assignee.displayName // .fields.assignee.displayName // "—")",
  "Reporter:   \(.reporter.displayName // .fields.reporter.displayName // "—")",
  "Team:       \((.customfield_10600.name // .fields.customfield_10600.name) // "—")",
  "Capability: \(((.customfield_11907 // .fields.customfield_11907) // []) | map(.value) | join(", "))",
  "Labels:     \((.labels // .fields.labels // []) | join(", "))",
  "Parent:     \((.parent.key // .fields.parent.key) // "—")",
  ""
'

echo "-- Children (sub-tasks) --"
printf '%s\n' "$ISSUE" | jq -r '(.subtasks // .fields.subtasks // [])[]? | "  \(.key)\t\(.fields.status.name)\t\(.fields.summary)"'
echo ""

echo "-- Linked issues --"
printf '%s\n' "$ISSUE" | jq -r '(.issuelinks // .fields.issuelinks // [])[]? |
  (.type.inward + ": " + (.inwardIssue.key // "?")) // (.type.outward + ": " + (.outwardIssue.key // "?"))'
echo ""

echo "-- MRs (all sources: remoteLinks + JSM Relevant Link + description + comments) --"
mrs=$(find_mr_urls "$KEY")
if [ -z "$mrs" ]; then
  echo "  (none found)"
else
  printf '  %s\n' $mrs
fi
echo ""

echo "-- Comments (last 20) --"
printf '%s\n' "$ISSUE" | jq -r '((.comment.comments // .fields.comment.comments // [])[-20:])[]? |
  "[\(.created | .[0:16])] \(.author.displayName // .author.emailAddress // "?"):",
  "  \(.body | tostring | .[0:400])",
  ""'
```

## Deep mode — pull the ticket AND its related tickets (one level)

The plain pull lists related KEYs but does not fetch their content. Deep mode walks parent + subtasks + issuelinks and pulls their headers + MRs in one batch. Does NOT recurse (a 2-level walk explodes; ask the operator if a specific KEY needs a follow-up drill).

**Batch principle**: one `twg jira workitem bulk-get` call for all related headers, one `find_mr_urls` per related KEY.

```bash
KEY="$1"

ISSUE=$(twg jira workitem get "$KEY" --full -o json | jq '.[0]')

# Collect related KEYs (dedup, drop the root).
RELATED=$(printf '%s' "$ISSUE" | jq -r '
  [ (.parent.key // .fields.parent.key // empty),
    ((.subtasks // .fields.subtasks // [])[]?.key),
    ((.issuelinks // .fields.issuelinks // [])[]? | (.inwardIssue.key // .outwardIssue.key))
  ] | map(select(. != null)) | unique | .[]')

if [ -z "$RELATED" ]; then
  echo "No related tickets — deep mode collapses to plain." >&2
  exit 0
fi

# Batch header pull — ONE call regardless of count.
# shellcheck disable=SC2086
RELATED_JSON=$(twg jira workitem bulk-get $RELATED \
  --fields "summary,status,assignee,issuetype,customfield_10600,customfield_11907,resolution,updated" \
  -o json)

# MRs per related KEY via find_mr_urls (defined in jiraai cookbook).
n=$(printf '%s\n' "$RELATED" | grep -c .)
if [ "$n" -gt 10 ]; then
  echo "Related pool is $n tickets — MR hunt skipped by default. Rerun with --with-mrs to fetch." >&2
  MR_LINES=''
else
  MR_LINES=$(for k in $RELATED; do find_mr_urls "$k" | awk -v k="$k" '{print k"\t"$0}'; done)
fi

echo "=== $KEY related tickets ==="
printf 'KEY\tTYPE\tSTATUS\tASSIGNEE\tSUMMARY\n'
printf '%s\n' "$RELATED_JSON" | jq -r '.[] |
  [ .key,
    (.fields.issuetype.name // .issuetype.name),
    (.fields.status.name // .status.name),
    ((.fields.assignee.displayName // .assignee.displayName) // "—"),
    (.fields.summary // .summary)
  ] | @tsv'

echo ""
echo "=== MRs on related tickets (all sources) ==="
if [ -z "$MR_LINES" ]; then
  echo "(none found)"
else
  printf '%s\n' "$MR_LINES"
fi
```

## Deep mode — recommended artifact layout

Write two files next to the ticket work:

```text
$ticket_dir/
├── ticket.md      # plain review of the root ticket (self)
├── related.md     # deep table + MR list (this section's output)
└── beads.json     # populated by jira-ticket via beads-decompose
```

`related.md` is what downstream skills consume:

- **jira-explore**: reads it to widen prior-art search and spot in-flight duplicates.
- **jira-ticket**: for every MR URL in `related.md`, files a `phase:watch-related-mr` bead (labeled `blocking:human` when the MR is in a repo the operator does not own).
- **ci-watch**: given a related MR URL, spawn a herdr split scoped to that MR's pipeline.
- **jira-fix**: if a related ticket already has a merged MR fixing the same root cause, this is the "you may be about to duplicate work" signal.

## When to use deep mode

- **Start of a support ticket** (from `jira-explore` step 1).
- **Incident triage** — Datadog-flagged tickets often link to a root-cause ticket in another team's project.
- **Before opening a fix MR** — check if a related ticket already has an in-flight MR.
- **Refinement / planning** — one root Feature + all its Stories + all their sub-tasks in a single glance.

Do NOT use it as the default when you only need the ticket itself (quick status check, single comment thread read) — plain mode is cheaper.

## Recommended output shape (what the AGENT should show the human)

```text
GT-2500  In Progress  Task  ([Team] X, Delivery management)  Julien DAULIAC
  ↑ parent GT-2461 Feature "General Enablers"
  ↓ children:  (none)
  Links:  Blocks GT-2600 · Relates GT-2300
  MRs:    !123 "Wire pulse/delivery/gitlab-ci-templates" (in review)
  Last activity 2026-09-08 09:44 by <Teammate Name>:
    "Approved v2, please rebase before merge."
  Full: https://corp.atlassian.net/browse/GT-2500
```

## When to use

- Before a comment — read the thread first, don't reply blind.
- Before a transition — verify current state.
- When triaging a stack of tickets (loop `jiraai-review` per KEY).
- After a bulk `jiraai-group` operation — verify representative tickets look right.

## Composes with

- **`twg-jira`**: primary — `get --full` and `bulk-get` are the workhorses.
- **`jiraai`**: owns `find_mr_urls` (the 5-source MR union) + PLAT edges.
- **`jiraai-link`**: verify what's already linked before adding more.
- **`jira-explore` / `jira-ticket`**: consume deep mode's `related.md`.
- **`ci-watch`**: open pipeline panes for related MR URLs surfaced by deep mode.
- **`beads`**: `related.md`'s MR-URL list becomes `phase:watch-related-mr` beads (via `beads-decompose` when driven from `jira-ticket`).
