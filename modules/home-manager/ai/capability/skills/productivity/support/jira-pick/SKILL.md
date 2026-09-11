---
name: jira-pick
description: Pick an unassigned Incoming ticket from the PLAT support queue (https://corp.atlassian.net/jira/servicedesk/projects/PLAT/queues/custom/361), assign it to the operator, transition it to "On hold", AND set Platform Capability (`customfield_11907`) if empty — required at close-out, cheaper to set at claim. Runs three atomic `twg jira workitem` calls (assign → transition → capability) then hands off to `jira-ticket` for the full explore → fix → answer pipeline. Trigger on "grab an incoming", "pick a support ticket", "claim the next PLAT", "start my on-call rotation", "what's in the PLAT queue", "next ticket please", "I'm on support today". Read-only if the operator just wants to see the queue; mutating (claim + transition + capability) only after explicit user pick.
---

# jira-pick — claim the next Incoming PLAT ticket

Turn "I'm on support today" into a claimed ticket ready for `jira-ticket` to orchestrate. Two phases: **browse** (read-only, always run first) and **claim** (mutating, only after user selects).

## Prerequisites

- `twg` on PATH with OAuth valid (`twg env`). See `twg-jira`.
- Read `jiraai` for the PLAT Platform Capability catalog + hierarchy edges.

## PLAT workflow — NOT the same as GT

PLAT (Service Management project) uses different transition IDs than GT. Always re-discover via `twg jira workitem transition --id <KEY>` — the table below is a snapshot as of 2026-09 for a PLAT Service Request:

| Status name | Transition id |
| --- | --- |
| In progress | 6 |
| On hold | 3 |
| Waiting for customer | 4 |
| Done | 2 |

PLAT statuses observed: `Incoming`, `In progress`, `On hold`, `Waiting for customer`, `Waiting for support`, `DONE`. `twg update --status "On hold"` accepts the status NAME (not ID) and resolves internally — prefer that over `bulk-transition --transition-id`.

## Phase 1 — Browse (read-only, ALWAYS run first)

```bash
twg jira workitem query \
  --jql 'project = PLAT AND assignee IS EMPTY AND status = "Incoming" ORDER BY priority DESC, created ASC' \
  --limit 50 -o json \
  | jq -r '.. | objects | select(.key? and .fields?) | [
      .key,
      (.fields.priority.name // "—"),
      (.fields.reporter.displayName // "—"),
      (.fields.created[0:10]),
      .fields.summary
    ] | @tsv' \
  | column -ts $'\t'
```

**Present the top ~10 to the operator.** Never auto-pick — the operator decides who takes what.

## Phase 2 — Claim (mutating, requires user pick)

Ask the user which key to claim. On answer:

```bash
ticket=<PICKED-KEY>   # e.g. PLAT-4033

# 1. Confirm the ticket is STILL unassigned + Incoming — a peer may have grabbed it.
current=$(twg jira workitem get "$ticket" --fields status,assignee -o json \
  | jq -r '.[0] | "\(.fields.status.name // .status.name)\t\(.fields.assignee.accountId // .assignee.accountId // "unassigned")"')
IFS=$'\t' read -r cur_status cur_assignee <<<"$current"
if [ "$cur_status" != "Incoming" ] || [ "$cur_assignee" != "unassigned" ]; then
  echo "Race: $ticket is now status=$cur_status assignee=$cur_assignee. Aborting." >&2
  exit 1
fi

# 2. Assign to me FIRST (short-circuits the race window for peers).
twg jira workitem update --id "$ticket" --assignee me

# 3. Transition to On hold. twg accepts the status name; it resolves the
#    per-issue-type transition ID internally, avoiding the PLAT-vs-GT ID trap.
twg jira workitem update --id "$ticket" --status "On hold"

echo "Claimed $ticket — assigned to me, moved to On hold."

# 4. Platform Capability — MANDATORY at claim (required at Done). Multi-option
#    field. Check current; if empty OR ["ALL"] / ["Global"] placeholder, prompt
#    operator. See jiraai cookbook § PLAT Platform Capability for the full catalog.
current_cap=$(twg jira workitem get "$ticket" --fields customfield_11907 -o json \
  | jq -r '(.[0].fields.customfield_11907 // .[0].customfield_11907 // []) | map(.value) | join(",")')
if [ -z "$current_cap" ] || [ "$current_cap" = "ALL" ] || [ "$current_cap" = "Global" ]; then
  echo "Ticket $ticket has NO Platform Capability. Pick one:" >&2
  echo "  (common: Delivery management, Databases, Service communication," >&2
  echo "   Observability, Edge, IAM, Cloud compute, Application management," >&2
  echo "   Container orchestrators, Events, Security, FinOps, Not applicable)" >&2
  echo "  Full list: jiraai cookbook § PLAT Platform Capability values" >&2
  printf "  > " >&2
  read -r chosen_cap </dev/tty
  [ -n "$chosen_cap" ] || { echo "empty pick — aborting" >&2; exit 1; }
  twg jira workitem update --id "$ticket" --field "Platform Capability=$chosen_cap"
  echo "Set Platform Capability = '$chosen_cap' on $ticket."
else
  echo "Platform Capability already set: $current_cap (leaving as-is)."
fi
```

**Order matters**: assign FIRST, transition SECOND, capability THIRD. Assignment blocks peer double-pick; transition is the public signal; capability can be corrected later if wrong but must be present.

## Phase 3 — Hand off to `jira-ticket`

Once claimed, hand off with the picked key:

```bash
export ticket
# jira-ticket sets up the try dir, bead, warm Dust conversation, herdr tab
# (or spawns a new one if the current tab already claims another ticket),
# and drives explore → fix → answer.
```

Do NOT try to do the whole pipeline from `jira-pick` — its scope ends at "one ticket is now mine and quiet in On hold". Everything downstream is `jira-ticket`'s job.

## Batch claim — refuse

If the operator asks to claim multiple tickets at once from the queue, refuse and explain: On hold means "waiting for me to start work", claiming five at once defeats the queue's purpose and blocks peer visibility. One at a time; finish or park, then pick another.

## Gotchas

- **Queue URL vs JQL.** The Service Desk queue `custom/361` is a server-side filter you cannot query directly without service-desk agent permissions. The JQL above approximates it (project + status + unassigned). If it drifts from the real queue, re-check the filter definition in the Jira UI.
- **Race with peers.** Between Phase 1 (browse) and Phase 2 (claim), a peer may grab your candidate. Always re-check status + assignee in Phase 2 step 1 before mutating. Fail fast on race.
- **Never post a comment from this skill.** Claiming is silent — moving the ticket to On hold is the signal to the reporter that someone owns it. If you want to add "picked up by @me, will look today", use `jira-answer` after `jira-explore` produces `proof.md`, not here.
- **Never touch tickets you did not pick.** No bulk transitions from this skill — that's `jiraai-group`'s job, with its own preview + confirm gate.

## Composes with

- **`jira-ticket`** (next: full pipeline for the picked ticket).
- **`jira-explore` / `jira-fix` / `jira-answer`** (downstream phases).
- **`twg-jira`** — every workitem read/write.
- **`jiraai`** — PLAT Platform Capability catalog + hierarchy edges.
- **`jiraai-review`** — brief on the ticket after claiming, before running `jira-ticket` setup.
