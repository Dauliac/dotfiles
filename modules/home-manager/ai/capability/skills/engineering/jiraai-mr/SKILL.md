---
name: jiraai-mr
description: End-to-end orchestrator for the "one Jira ticket per GitLab MR" workflow at ManoMano. Given a branch (or the intent to start one), (1) creates a Task in the default project via `twg jira workitem create`, (2) captures the KEY, (3) renames/creates the branch to embed the KEY, (4) prepends the KEY to commit messages via a prepare-commit-msg helper, (5) opens the MR via `glab mr create` with the Jira URL in the description, (6) posts a reciprocal Jira remoteLink via `jiraai-link mr`. Triggers on "start work on X", "spin up a ticket for this branch", "create a ticket and MR for this feature", "new work: X", "open a Jira and MR for this", "one ticket per MR", "wire this branch to Jira".
---

# jiraai-mr — one-ticket-per-MR orchestrator

Composes primitives (`twg jira workitem create` + `jiraai-link`) to run the full
"start of work" flow in one call. Never fires mutating steps without user OK.

## Prerequisites

- Read `jiraai` (sibling) for auth, defaults, hierarchy.
- Read `twg-jira` for the `twg jira workitem create` ticket-creation shape.
- Read `jiraai-link` for the two-sided ticket↔MR link mechanics.
- `glab` on PATH, `glab auth status` = OK.

## Flow

```text
                            ┌────────────────────────┐
   "start work on X"  ───►  │  ask: title + type +   │
                            │  parent Feature (opt)  │
                            └───────────┬────────────┘
                                        │  (preview)
                                        ▼
                            ┌────────────────────────┐
                            │  twg jira workitem     │
                            │  create --type Task    │
                            │  → $KEY = XX-2xxx      │
                            └───────────┬────────────┘
                                        ▼
                            ┌────────────────────────┐
                            │  git checkout -b       │
                            │   feat/$KEY-<slug>     │
                            └───────────┬────────────┘
                                        ▼
                            ┌────────────────────────┐
                            │  (work happens; commits│
                            │  auto-prefixed [$KEY]  │
                            │  via jiraai-commit-    │
                            │  check hook)           │
                            └───────────┬────────────┘
                                        ▼
                            ┌────────────────────────┐
                            │  git push -u origin    │
                            └───────────┬────────────┘
                                        ▼
                            ┌────────────────────────┐
                            │  glab mr create        │
                            │   --description with   │
                            │   Jira URL             │
                            │  → $MR_URL             │
                            └───────────┬────────────┘
                                        ▼
                            ┌────────────────────────┐
                            │  jiraai-link mr        │
                            │   $KEY $MR_URL         │
                            │  (Jira remoteLink +    │
                            │   glab mr note)        │
                            └────────────────────────┘
```

## Concrete steps

### 1. Ask the operator for the essentials

```text
- Title (short, imperative): _____
- Type (Task/Story/Bug):     [Task]
- Parent Feature key (opt):  _____   # if this fits under an existing Feature
- Team UUID (REQUIRED):      _____   # customfield_10600; discover via
                                     # twg jira workitem field create-metadata
                                     # --space <PROJ> --type <TYPE>
- Assignee:                  [me]
```

**Team is non-negotiable** for every non-Sub-task create. The `jira-mr-coherence` gate hook denies `twg jira workitem create` outright when `--field "Team=..."` is missing (unless `--type Sub-task`). If you do not know the Team UUID, stop and ask the operator before issuing any create command  -  do NOT ship a Task without it and plan to patch it afterwards.

### 2. Preview → wait for OK

```text
About to create:
  Type:     Task
  Parent:   XX-2461 "General Enablers"
  Summary:  "Add retry policy to Kafka consumer"
  Team:     <UUID>              # REQUIRED; hook denies create without it
  Capability: Delivery management
  Labels:   ${INITIATIVE_LABEL}

Confirm? [y/N]
```

If the Team row shows a placeholder (`?`, `TBD`, `<UUID>` literal) instead of a real UUID, DO NOT proceed. Loop back to step 1.

### 3. Create the ticket (see `twg-jira` for the `twg jira workitem create` form; curl fallback below)

```bash
KEY=$(curl -sS -u "$AUTH" -X POST "$ROOT/issue" -H 'Content-Type: application/json' -d '{
  "fields": {
    "project": {"key": "XX"},
    "issuetype": {"name": "Task"},
    "parent": {"key": "XX-2461"},
    "summary": "Add retry policy to Kafka consumer",
    "labels": ["${INITIATIVE_LABEL}"],
    "customfield_11907": [{"value": "Delivery management"}],
    "customfield_10600": "${TEAM_UUID}"
  }
}' | jq -r '.key')
echo "Created $KEY"
```

### 4. Branch name encodes the KEY

```bash
SLUG=$(echo "add-retry-policy" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
git checkout -b "feat/$KEY-$SLUG"    # e.g. feat/XX-2601-add-retry-policy
```

Convention: `<type>/<KEY>-<slug>`. `jiraai-commit-check` (sibling) then
extracts the KEY from the branch and prepends it to commits.

### 5. Open the MR with the Jira URL in description

```bash
JIRA_URL="https://${SITE}/browse/$KEY"

glab mr create \
  --assignee "@me" \
  --title "[$KEY] Add retry policy to Kafka consumer" \
  --description "$(cat <<EOF
Related Jira: [$KEY]($JIRA_URL)

## What
Adds an exponential-backoff retry policy to the Kafka consumer.

## Why
Fixes DLQ growth observed since 2026-09-01 (see $KEY for repro + logs).
EOF
)"

# Capture the MR URL for the reciprocal link
MR_URL=$(glab mr view --output json | jq -r '.web_url')
echo "MR: $MR_URL"
```

### 6. Reciprocal Jira remoteLink (see `jiraai-link`)

```bash
curl -sS -u "$AUTH" -X POST "$ROOT/issue/$KEY/remotelink" -H 'Content-Type: application/json' -d "$(jq -n \
  --arg url "$MR_URL" --arg title "MR: Add retry policy to Kafka consumer" \
  --arg globalid "system=gitlab&url=$MR_URL" \
  '{
    globalId: $globalid,
    application: { type: "com.atlassian.jira", name: "GitLab" },
    relationship: "implemented by",
    object: { url: $url, title: $title, icon: { url16x16: "https://gitlab.com/favicon.ico", title: "GitLab" } }
  }')"
```

### 7. Transition the ticket to In Progress (optional but nice)

```bash
curl -sS -u "$AUTH" -X POST "$ROOT/issue/$KEY/transitions" -H 'Content-Type: application/json' \
  -d '{"transition":{"id":"31"}}'   # 31 = In Progress for Story/Task/Bug/Sub-task/Feature
```

## Idempotency

Re-running mid-flow is safe:

- If the branch already exists → skip step 4.
- If the ticket already exists (KEY extractable from branch name) → skip step 3.
- If a remoteLink for the same MR URL already exists → the POST updates it (globalId dedupes).

## When to skip parts of this flow

- **No parent Feature** — Task can be created at level 0 with no parent (just omit `parent`); it'll orphan-hang under the project. Ask user.
- **Branch already pushed** — skip 4-5, jump to 6 (link the existing MR).
- **Ticket already exists** — skip 1-3, jump to 4 (or 5 if branch too).

## Composes with

- **`jiraai`**: parent — API + defaults
- **`twg-jira`**: `twg jira workitem create` (step 3) and `twg jira workitem update --status ...` (step 7 transition)
- **`jiraai-link`**: step 6
- **`jiraai-commit-check`**: keeps [$KEY] in commit messages once branch is set
- **`glab`**: MR creation + view
