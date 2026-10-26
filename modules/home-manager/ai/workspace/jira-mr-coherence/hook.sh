#!/usr/bin/env bash
# jira-mr-coherence: enforce Jira ticket + GitLab MR + status coherence
# by nagging the agent into using the right skills.
#
# Scope: GT and PLAT project prefixes only.
#
# Four modes sharing one per-session statefile:
#
#   anchor : UserPromptSubmit. Scan prompt for GT-/PLAT- ids or Jira /
#            GitLab URLs. If found, inject a skill-activation reminder
#            telling the agent to Skill(jiraai-mr) + Skill(jiraai-link)
#            before any Bash call touching twg or glab.
#   gate   : PreToolUse Bash. Detect sensitive twg / glab operations.
#            Two sub-rules:
#              (a) soft: emit permissionDecision=ask with a reason
#                  naming the required skill (create / transition /
#                  mr-create / link).
#              (b) hard: emit permissionDecision=deny when
#                  `twg jira workitem create` is non-Sub-task AND
#                  `--field "Team=..."` is missing. Jira field
#                  `customfield_10600` is the team routing anchor;
#                  tickets created without it hang orphaned off every
#                  team board. Sub-task inherits Team from parent and
#                  is exempt (see jiraai SKILL §Hierarchy trap).
#   record : PostToolUse Bash. Only runs after a successful tool call.
#            Bumps pending counters for pairs that must be closed:
#              create                  ->  pending_transitions++
#              create (no Team, slipped) -> pending_team_sets++
#              update --field Team=... ->  pending_team_sets--
#              transition              ->  pending_transitions--
#              mr-create               ->  pending_links++
#              link                    ->  pending_links--
#   drift  : Stop. If any pending counter is > 0, emit decision=block
#            with a reason telling the agent which pair is open.
#
# Known limitation: if the user runs the paired action manually outside
# Claude, the counter will not decrement and drift will nag once. Clear
# with XI_DISABLE_JIRA_MR_COHERENCE_HOOK=1 for the next Stop, or delete
# the statefile.
#
# Runtime kill-switch (per session):
#   XI_DISABLE_JIRA_MR_COHERENCE_HOOK=1 claude
#
# Wired via .claude/settings.d/35-jira-mr-coherence.json (see
# jira-mr-coherence.nix).

set -euo pipefail

if [[ -n "${XI_DISABLE_JIRA_MR_COHERENCE_HOOK:-}" ]]; then
  exit 0
fi

mode=${1:?usage: jira-mr-coherence.sh anchor|gate|record|drift}
payload=$(cat)

session_id=$(printf '%s' "$payload" | jq -r '.session_id // "unknown"')
state_dir="${XDG_RUNTIME_DIR:-/tmp}/claude-jira-mr-coherence"
state_file="$state_dir/$session_id.json"
mkdir -p "$state_dir"
[[ -f "$state_file" ]] || printf '{"pending_transitions":0,"pending_links":0,"pending_team_sets":0}\n' > "$state_file"

classify_cmd() {
  local cmd=$1
  if   printf '%s' "$cmd" | grep -qE 'twg jira workitem create\b';     then echo create
  elif printf '%s' "$cmd" | grep -qE 'twg jira workitem transition\b'; then echo transition
  elif printf '%s' "$cmd" | grep -qE 'glab mr create\b';               then echo mr-create
  elif printf '%s' "$cmd" | grep -qE 'twg jira workitem link pr\b';    then echo link
  elif printf '%s' "$cmd" | grep -qE 'twg jira workitem update\b';     then echo update
  else echo none
  fi
}

# True (0) if `twg jira workitem create` carries --type Sub-task.
# Matches: --type Sub-task | --type=Sub-task | --type "Sub-task" | --type sub-task
is_subtask_create() {
  printf '%s' "$1" | grep -qiE -- '--type[[:space:]=]+("|'\'')?sub-task\b'
}

# True (0) if the command carries --field "Team=..." (any quoting / casing on key).
has_team_field() {
  printf '%s' "$1" | grep -qiE -- '--field[[:space:]=]+("|'\'')?Team[[:space:]]*='
}

bump_state() {
  local field=$1 delta=$2 tmp
  tmp=$(mktemp)
  jq --arg f "$field" --argjson d "$delta" '
    .[$f] = ([(.[$f] + $d), 0] | max)
  ' "$state_file" > "$tmp"
  mv "$tmp" "$state_file"
}

case "$mode" in
  anchor)
    prompt=$(printf '%s' "$payload" | jq -r '.prompt // ""')
    if printf '%s' "$prompt" | grep -qE '\b(GT|PLAT)-[0-9]+\b|atlassian\.net|gitlab\.'; then
      cat <<'EOF'
JIRA-MR COHERENCE: this prompt references a Jira ticket (GT or PLAT) or
a Jira / GitLab URL. Before any Bash call touching `twg` or `glab`, you
MUST call Skill(jiraai-mr) and Skill(jiraai-link). The gate hook will
prompt before each sensitive tool call; the drift hook will refuse to
end the turn if `twg jira workitem create` is not followed by a
transition, or if `glab mr create` is not followed by
`twg jira workitem link pr`.
EOF
    fi
    ;;

  gate)
    cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
    kind=$(classify_cmd "$cmd")
    reason=""
    decision="ask"
    case "$kind" in
      create)
        if ! is_subtask_create "$cmd" && ! has_team_field "$cmd"; then
          decision="deny"
          reason="BLOCKED: twg jira workitem create is missing --field \"Team=<UUID>\". Team (customfield_10600) is required on every non-Sub-task create  -  tickets without it hang orphaned off team boards. Fix: look up the UUID (twg jira workitem field create-metadata --space <PROJECT> --type <TYPE> prints allowed Team values), then re-run with --field \"Team=<UUID>\" added. Sub-task is exempt (inherits Team from parent). Kill-switch for emergencies: XI_DISABLE_JIRA_MR_COHERENCE_HOOK=1."
        else
          reason="About to create a Jira workitem. Call Skill(jiraai-mr) and Skill(jiraai-link) first, then transition to In Progress and link the paired MR immediately after."
        fi
        ;;
      transition)
        reason="About to transition a Jira workitem. Call Skill(jiraai) first (hasScreen handling, link-type-id enums, Resolution requirement for Rejected / Won'\''t Do)." ;;
      mr-create)
        reason="About to open a GitLab MR. Call Skill(jiraai-mr) and Skill(jiraai-link) first; create or link the paired Jira ticket in the same flow." ;;
      link)
        reason="About to link an MR to a Jira ticket. Call Skill(jiraai-link) first; add the reciprocal GitLab-side note too." ;;
      update|none)
        exit 0 ;;
    esac
    jq -n --arg r "$reason" --arg d "$decision" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: $d,
        permissionDecisionReason: $r
      }
    }'
    ;;

  record)
    cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
    kind=$(classify_cmd "$cmd")
    case "$kind" in
      create)
        bump_state pending_transitions 1
        # Belt-and-braces: the gate normally denies this, but if it was
        # bypassed (kill-switch, raw curl path, pre-rollout session),
        # register the missing Team so drift catches it at Stop.
        if ! is_subtask_create "$cmd" && ! has_team_field "$cmd"; then
          bump_state pending_team_sets 1
        fi
        ;;
      update)
        # Any `twg jira workitem update ... --field "Team=..."` closes
        # one open team-set debt. We do not try to pair by KEY  -  the
        # counter is coarse on purpose; false-decrements are preferable
        # to false-nags.
        if has_team_field "$cmd"; then
          bump_state pending_team_sets -1
        fi
        ;;
      transition) bump_state pending_transitions -1 ;;
      mr-create)  bump_state pending_links 1 ;;
      link)       bump_state pending_links -1 ;;
    esac
    ;;

  drift)
    pt=$(jq -r '.pending_transitions // 0' "$state_file" 2>/dev/null || echo 0)
    pl=$(jq -r '.pending_links // 0'        "$state_file" 2>/dev/null || echo 0)
    pts=$(jq -r '.pending_team_sets // 0'   "$state_file" 2>/dev/null || echo 0)
    if (( pt > 0 )) || (( pl > 0 )) || (( pts > 0 )); then
      msg="jira-mr-coherence drift:"
      (( pt > 0 ))  && msg="$msg $pt Jira workitem create(s) without a matching transition."
      (( pl > 0 ))  && msg="$msg $pl MR create(s) without a matching twg link pr."
      (( pts > 0 )) && msg="$msg $pts non-Sub-task create(s) without a Team field  -  tickets are orphaned from team boards until Team=<UUID> is set."
      msg="$msg Close the loop now (twg jira workitem transition --transition-id 31 for In Progress; twg jira workitem link pr for MR to ticket; twg jira workitem update --id <KEY> --field \"Team=<UUID>\" to adopt). If the pair was done manually outside Claude, delete $state_file and retry."
      jq -n --arg m "$msg" '{decision: "block", reason: $m}'
    fi
    ;;

  *)
    echo "jira-mr-coherence.sh: unknown mode '$mode' (expected anchor|gate|record|drift)" >&2
    exit 1
    ;;
esac
