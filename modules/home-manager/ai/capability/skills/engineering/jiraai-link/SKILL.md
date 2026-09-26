---
name: jiraai-link
description: Link things to a Jira ticket in ${SITE}. Two modes — (a) ticket↔ticket via `twg jira workitem link workitem`, (b) ticket↔MR via `twg jira workitem link pr` (Jira side, idempotent via generated globalId) PLUS a reciprocal `glab mr note` on the GitLab side so both surfaces show the relationship. Triggers on "link XX-1 to XX-2", "mark X as blocking Y", "XX-1234 is a duplicate of", "attach this MR to the ticket", "link !123 to XX-1234", "one ticket per MR", "connect the MR and the Jira", "add the Jira remote link".
---

# jiraai-link — connect tickets to tickets and tickets to MRs

Two link modes; use them together for the "one ticket per MR" flow.

## Prerequisites

- `twg` on PATH with OAuth valid (`twg env`). See `twg-jira`.
- For MR-side notes: `glab` on PATH, `glab auth status` returns OK.

## Mode A — ticket ↔ ticket (issue link)

```bash
# Discover link-type names + inward/outward direction first if unfamiliar.
twg jira workitem link workitem --id GT-100 --target-id GT-200 --link-type-id Blocks
# GT-100 "blocks" GT-200 in this direction. Reverse by swapping --id / --target-id.
```

Repeat `--target-id` for multiple targets in one call. `--link-type-id` accepts a link-type name (`Blocks`, `Cloners`, `Duplicate`, `Relates`, `Problem/Incident`) or its numeric ID.

## Mode B — ticket ↔ MR (Jira remote link + GitLab note)

Both sides need to know so BOTH surface the link. **Jira side** puts the MR in the ticket's Development panel; **GitLab side** puts the Jira URL on the MR so anyone reading the MR sees the ticket.

### Step 1 — Jira remote link (twg, idempotent)

```bash
KEY="GT-2500"
MR_URL="https://$GITLAB_HOST/<group>/<repo>/-/merge_requests/123"

twg jira workitem link pr --id "$KEY" --target "$MR_URL"
# → Idempotent via a generated globalId; re-running updates rather than duplicates.
```

Other typed artifact-link verbs when the link isn't a PR: `branch`, `commit`, `build`, `deployment`, `repo`, `page`, `loom`, `meeting`, `weblink`, `artifact`, `goal`.

### Step 2 — GitLab-side note

```bash
JIRA_URL="https://corp.atlassian.net/browse/$KEY"
glab mr note "$MR_URL" --message "Jira: $JIRA_URL"
# or by IID in the current repo:
glab mr note 123 --message "Jira: $JIRA_URL"
```

Cleaner alternative — put the Jira URL in the MR **description** so it's front and center:

```bash
CURRENT_DESC=$(glab mr view 123 --output json | jq -r '.description // ""')
glab mr update 123 --description "$CURRENT_DESC

Related: [$KEY]($JIRA_URL)"
```

## Verify both sides

```bash
# Jira side — remoteLinks + every custom field via --full (unions with find_mr_urls semantics)
twg jira workitem get "$KEY" --full -o json | jq -r '.[0].remoteLinks[]?.url'
# GitLab side
glab mr view 123 --output json | jq -r '.description'
```

## Rules of engagement

- **Idempotency**: `twg link pr` generates a stable globalId from the MR URL — safe to re-run.
- **Never link secrets**: don't paste a token, `.env`, or a private preview URL into a public Jira comment / MR note.
- **`glab mr note` is not idempotent**: check for an existing note before adding.

## Composes with

- **`twg-jira`**: primary — owns the Jira half of every link write.
- **`jiraai`**: PLAT edges (JSM Relevant Link custom field where the reporter drops MRs).
- **`glab`**: GitLab-side reciprocal note / description edit.
- **`jiraai-mr`**: orchestrator that runs create+link in one shot.
