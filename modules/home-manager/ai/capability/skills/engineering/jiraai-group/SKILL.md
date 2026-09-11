---
name: jiraai-group
description: Bulk-operate on many Jira tickets in ${SITE} with a preview + confirm gate. Uses `twg jira workitem bulk-transition --dry-run` for native transition previews and shell loops over `twg jira workitem update` / `link` / `comment` for other bulk ops. Always prints the planned diff FIRST and pauses for user OK before firing. Triggers on "bulk transition all X to Done", "add label Y to every ticket in Z", "reassign these 20 tickets to me", "close all resolved child tickets of XX-2457", "apply this to every ticket in the initiative", "batch update", "mass reassign".
---

# jiraai-group — bulk operations with a preview gate

Bulk mutation is expensive to undo. This skill's job is to make the plan visible BEFORE anything is fired.

## Prerequisites

- `twg` on PATH with OAuth valid (`twg env`). See `twg-jira`.
- Read `jiraai` (sibling) for hierarchy traps + PLAT enum.

## Contract

1. **Gather** the KEY list — either from a `twg jira workitem query` result, a filter, or an explicit array.
2. **Preview** — for transitions use `twg bulk-transition --dry-run`; for other ops print the planned change per KEY.
3. **Wait for user OK** — do NOT fire without an explicit "yes / go / do it".
4. **Fire** — `twg bulk-transition --yes` for transitions; shell loop over `twg update` / `twg link` / `twg comment create` for other ops with per-ticket OK/FAIL counter.
5. **Report failures** verbatim (KEY + error body) — don't collapse.

## Example — bulk-transition every open sub-task of GT-2457 to Done

```bash
# Step 1 — gather
KEYS=$(twg jira workitem query \
  --jql 'project = GT AND issuetype = Sub-task AND parent in (parentIssue(GT-2457)) AND status != Done' \
  --limit 200 -o json \
  | jq -r '.. | objects | select(.key? and (.key | startswith("GT-"))) | .key' | sort -u)

# Step 2 — native preview (twg bulk-transition has --dry-run built in)
twg jira workitem bulk-transition --ids "$(echo $KEYS | tr ' ' ,)" --transition-id 41 --dry-run

# Step 3 — WAIT for the operator to type "y". Do NOT auto-continue in agent context.

# Step 4 — fire, one call
twg jira workitem bulk-transition --ids "$(echo $KEYS | tr ' ' ,)" --transition-id 41 --yes
```

`--transition-id` requires the numeric ID (twg does not accept names for `bulk-transition`). Discover with `twg jira workitem transition --id <SAMPLE_KEY> -o json | jq -r '.data.transitions[] | "\(.id)\t\(.name)"'`.

## Example — add a label to every ticket matching a JQL

```bash
KEYS=$(twg jira workitem query \
  --jql 'project = GT AND labels = pe-onboarding-2026' \
  --limit 200 -o json \
  | jq -r '.. | objects | select(.key? and (.key | startswith("GT-"))) | .key' | sort -u)

echo "Will add label 'q4-review' to $(echo $KEYS | wc -w) tickets:"
printf '  %s\n' $KEYS | head -20
echo '...'
# WAIT for OK

OK=0 ; FAIL=0
for k in $KEYS; do
  if twg jira workitem update --id "$k" --add-labels q4-review >/dev/null 2>err; then
    OK=$((OK+1))
  else
    FAIL=$((FAIL+1)); echo "  FAIL $k: $(head -c 200 err)"
  fi
done
rm -f err
echo "OK=$OK FAIL=$FAIL"
```

## Example — reassign 20 tickets to me

```bash
KEYS='GT-2500 GT-2501 GT-2502 ...'   # explicit array in this case
echo "Will reassign to me:"
printf '  %s\n' $KEYS
# WAIT for OK

OK=0 ; FAIL=0
for k in $KEYS; do
  if twg jira workitem update --id "$k" --assignee me >/dev/null 2>err; then
    OK=$((OK+1))
  else
    FAIL=$((FAIL+1)); echo "  FAIL $k: $(head -c 200 err)"
  fi
done
rm -f err
echo "OK=$OK FAIL=$FAIL"
```

## Anti-patterns

- **Firing without a preview** — even for "small" batches, print the plan.
- **Silent failures** — always report per-ticket exit code; don't just count OKs.
- **No idempotency thinking** — a re-run should either be a no-op or converge. Check current state before mutating (`twg workitem get --fields status`).
- **Sub-task team update** — `twg update --id <SUBTASK> --field "Team=..."` fails on Sub-task. Set team on parent Story/Task/Bug instead.

## Composes with

- **`twg-jira`**: primary — `bulk-transition` (native `--dry-run`), `update`, `link`, `comment`.
- **`jiraai`**: hierarchy traps + PLAT enum.
- **`jiraai-review`**: sanity-check 2-3 representative tickets after the batch runs.
