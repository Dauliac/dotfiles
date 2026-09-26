---
name: jiraai
description: Residue cookbook for Jira Cloud operations against ${SITE} that the `twg` CLI cannot express — the JSM-Relevant-Link 5-source MR union (`find_mr_urls`), the hierarchy narrative (Bet-Initiative → Feature → Story/Task/Bug → Sub-task), the PLAT sub-task team-inheritance trap, the PLAT capability enum, and the sops-token break-glass for when twg OAuth is unavailable. Every write, read, JQL, transition, comment, link, and field-metadata call goes through the `twg jira workitem ...` family — this skill exists for the tenant-specific edges twg does not model. Trigger on "why does my ticket not accept X", "which type can parent which", "how do I find every MR mentioned on a JSM ticket", "twg auth is broken, do we have a fallback", "what's the PLAT capability enum". For any generic Jira read/write, prefer `twg-jira` directly.
---

# jiraai — the twg-can't-do-this residue for Jira Cloud

**Default route**: `twg jira workitem <get|query|search|create|update|transition|comment|link|bulk-transition|field ...>`. See the `twg-jira` skill. This cookbook is only for the ManoMano-specific edges twg does not express.

## What twg replaces (do NOT hand-roll curl for these)

| Old skill / recipe | Now |
| --- | --- |
| `jiraai-comment` | `twg jira workitem comment create --issue-id KEY --body '...' --body-format markdown` |
| `jiraai-create` | `twg jira workitem create --space GT --type Task --summary '...' --parent PARENT-KEY --labels a,b --field 'Platform Capability=Delivery management' --assignee me -y` |
| `jiraai-edit` (fields, labels, assignee, status) | `twg jira workitem update --id KEY --summary '...' --assignee me --add-labels a,b --remove-labels c --status 'In Progress' --field 'Team=<UUID>' --field 'Platform Capability=Observability'` |
| `jiraai-list` (JQL) | `twg jira workitem query --jql "project = GT AND assignee = currentUser() AND resolution = Unresolved" --limit 50` |
| Field-ID / allowed-values discovery | `twg jira workitem field create-metadata --space GT --type Task` (returns `--field "Name=value"` syntax directly) |
| Transition-ID discovery | `twg jira workitem transition --id KEY` (no `--transition-id` = read-only enumeration) |
| Bulk transition | `twg jira workitem bulk-transition --ids K1,K2 --transition-id 41 --dry-run` then `--yes` |
| Read one ticket with everything (comments + remoteLinks + all customfield_*) | `twg jira workitem get KEY --full` |
| Batch header pull | `twg jira workitem bulk-get K1 K2 K3 --fields summary,status,assignee` |

## Custom-field IDs worth pinning (avoid a discovery round-trip)

| Name | ID | Type | twg `--field` syntax |
| --- | --- | --- | --- |
| Platform Capability | `customfield_11907` | multi-option | `--field "Platform Capability=Delivery management"` (or comma-list for multi: `"IAM,GDPR"`) |
| Team | `customfield_10600` | team | `--field "Team=<UUID>"` (bare UUID) |
| Relevant Link (JSM) | `customfield_11380` | any | rarely written; matters for `find_mr_urls` reads |

Re-discover with `twg jira workitem field create-metadata --space <PROJECT> --type <TYPE>` — that prints the exact `--field "Name=allowed,values"` syntax with operations (`set`/`add`/`remove`).

## Hierarchy — WHO CAN PARENT WHOM (unchanged; still a mental model)

| Level | Type | Valid parent | Notes |
| --- | --- | --- | --- |
| 2 | `Bet - Initiative` | (none — top) | Only 3 transitions from Backlog (Done, On Hold, self) |
| 1 | `Feature` | `Bet - Initiative` | Full 14-transition workflow |
| 0 | `Story`, `Task`, `Bug`, `Run`, `Feature Request`, `Service Request`, `Incident`, `Cost incident`, `WOOF topic` | `Feature` | **Siblings — Task cannot parent Story or vice versa** |
| -1 | `Sub-task` | `Story` / `Task` / `Bug` | Only way to nest below level 0 |

**Trap**: setting `--parent` on a level-0 type pointing to another level-0 issue → HTTP 400 `Please select valid parent issue.` Use `--type Sub-task` if you need to nest.

**Trap**: `Sub-task` inherits `Team` (`customfield_10600`) from its parent. `twg update --id <SUBTASK> --field "Team=..."` will be rejected. Set team on the parent Story/Task/Bug. `twg update --id <SUBTASK> --assignee me` **works fine** — the assignee split-endpoint trap that motivated raw curl no longer exists at the twg layer (verified 2026-09-10 on GT-2605).

## PLAT Platform Capability — allowed values (verified 2026-09)

PLAT (JSM) uses the same field id (`customfield_11907`) as GT but a different allowed catalog. Required at Done — `jira-pick` sets at claim, `jira-answer` refuses close-out if empty.

`IAM`, `GDPR`, `Service communication`, `Observability`, `Cloud compute`, `Container orchestrators`, `Events`, `Databases`, `Edge`, `Run management`, `Dev workspace`, `Delivery management`, `Testing`, `Application management`, `Not applicable`, `Quality`, `Eventing`, `Global`, `ALL`, `Containers Orchestrator`, `Corporate IT`, `FinOps`, `Incubator`, `Security`, `Incident management`.

Set via `twg jira workitem update --id PLAT-N --field "Platform Capability=Observability"`. Re-discover the catalog with `twg jira workitem field create-metadata --space PLAT --type "Service Request"`.

## `find_mr_urls` — 5-source union that twg has no primitive for

MR URLs on a Jira ticket can live in ANY of: `remoteLinks`, JSM `Relevant Link` custom field (`customfield_11380`), description ADF, comment ADF, attachments. `twg jira workitem get --full` returns all fields including project-scoped custom ones (verified against PLAT-4046). Recurse through the response with `jq '.. | strings'` and grep:

```bash
find_mr_urls() {
  local key=$1
  local pat='https?://(git\.corp\.tech|gitlab\.com)/[^ ")\]<>]+'
  twg jira workitem get "$key" --full -o json \
    | jq -r '.. | strings' \
    | grep -oE "$pat" \
    | sort -u
}
```

Every skill that infers "does this ticket have an MR?" MUST call `find_mr_urls` — never a bare `remoteLinks` read.

## Auth — twg first, sops break-glass second

**Primary**: `twg` uses its own OAuth (`~/.config/twg/auth_oauth.conf`, `twg env` reports current mode). No sops-token dance for normal use.

**Break-glass** (only when twg OAuth is expired / unavailable / a script needs to bypass twg entirely):

```bash
TOKEN=$(cat ~/.config/sops-nix/secrets/atlassian_api_token)
AUTH="user@corp.example:$TOKEN"
ROOT="https://corp.atlassian.net/rest/api/3"
curl -sS -u "$AUTH" "$ROOT/<endpoint>"
```

Note: `~/.local/share/jiraai/config.yaml` (the old defaults yaml) is **not required** — `twg` reads its own site/cloud-id from `~/.config/twg/`. If a skill still references `${SITE}` / `${USER_EMAIL}` / `${TEAM_UUID}` placeholders, treat them as documentation for the break-glass path only.

## Posting safety — freshness gate BEFORE every write

Jira is multi-writer. Between the moment an agent starts drafting a
comment / transition / field update and the moment it posts, a
teammate can invalidate the whole draft. Real incident: Vincent's
comment on PLAT-4095 (2026-09) flipped the ticket status — the naive
`twg jira workitem comment create` posted a stale reply anyway.

Every skill that writes to Jira MUST route through
`jiraai-freshness-check`:

- `freshness_snapshot KEY DIR` before drafting.
- `freshness_diff KEY DIR` immediately before the write.
- Refuse to post on `NEW_COMMENTS` / `STATUS_CHANGE` / `BOTH`.
- Downgrade `ASSIGNEE_CHANGE` to a warn for ownership-neutral writes.

This is a hard rule, not a suggestion. `jira-answer`, `jira-fix`,
`jira-review`, `jira-merge`, and `jiraai-group` already wire the
gate. New callers of `twg jira workitem comment create` /
`... update --status` / `... update --field` inherit the same rule.

## Composes with

- **`twg-jira`**: primary — every workitem read/write. This skill only supplies the edges.
- **`jiraai-mr`**: create-ticket-per-MR orchestrator.
- **`jiraai-commit-check`**: pre-commit hook — no Jira ID in message? ask to create one.
- **`jiraai-link`**: cross-side (Jira remoteLink + `glab mr note`) — twg owns the Jira half.
- **`jiraai-review`**: brief-me-on-ticket + related-work walk on top of `twg workitem get --full`.
- **`jiraai-group`**: bulk operations with preview + confirm on top of `twg workitem bulk-transition`.
- **`jiraai-freshness-check`**: mandatory pre-post gate on every
  Jira write (see `Posting safety` above). Snapshot at draft
  time; diff at post time; refuse on drift.
