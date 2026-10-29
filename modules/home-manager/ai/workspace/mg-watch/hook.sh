#!/usr/bin/env bash
# mg-watch: spawn one `mg` (mardi-gras) beads side-panel per repo, but only
# while a bead is actually in progress.
#
# Two modes sharing one spawn routine:
#
#   session-start : SessionStart. Payload has `cwd` (or $CLAUDE_PROJECT_DIR).
#                   Covers resuming a session that already holds a claimed
#                   bead  -  the pane comes back without the agent doing
#                   anything.
#   bd-activity   : PostToolUse on Bash, pre-filtered by the fragment's
#                   `if: "Bash(bd *)"`. The agent having just run `bd` IS
#                   the "a claude is driving beads" signal  -  see WIP GATE.
#
# WIP GATE. Both modes require `bd list --status in_progress` to be
# non-empty. There is no way to ask beads "is this claimed BY a claude":
# `bd update --claim` writes `assignee` from git user.name (verified:
# assignee "Dauliac", `actor` null), so the DB cannot distinguish an agent
# claim from a human one. The agent-ness comes from the EVENT, not the row  -
# bd-activity only fires because the agent ran bd through the Bash tool.
# SessionStart has no such evidence, so it is deliberately the weaker of the
# two triggers: it reopens a panel for work that was already in flight.
#
# Dedup (see DEDUP below): `herdr pane get <id>` on the non-agent panes of
# the CURRENT workspace, matching the `label` field. Do NOT match on
# `terminal_title*`  -  `herdr-tui launch` always runs the command through an
# `exec sh -c "$(printf '%s' <base64> | base64 -d)"` wrapper, so the title is
# that wrapper, never "mg". Title matching silently never fires, which leaks
# one new split per event (the bug lazygit-worktrees already paid for).
#
# `label` is only exposed by `herdr pane get`, not by `herdr pane list`, hence
# the per-candidate get. Candidates are cheap: agent panes are filtered out by
# `has("agent")`, so a workspace yields a handful at most.
#
# Cost ordering matters here, unlike lazygit-worktrees: the WIP gate costs one
# `bd list` (~0.6s), the dedup scan costs N `herdr pane get`. The gate runs
# FIRST and bails without writing the rate-limit stamp, so a `bd show` with no
# claimed bead pays 0.6s and nothing else  -  and a claim landing one second
# later is not suppressed by a stamp it never set.
#
# The spawn runs under `setsid --fork` so it survives the hook process group
# being torn down when the hook returns (a backgrounded `&` + disown does NOT
#  -  it stays in the hook's process group and gets killed mid-launch, which
# leaves a blank half-created pane behind).
#
# Runtime kill-switch (per session):
#   XI_DISABLE_MG_WATCH_HOOK=1 claude
#
# Companion skill: capability/skills/engineering/mg-watch/SKILL.md.
# Wired via .claude/settings.d/38-mg-watch.json (see mg-watch.nix).

set -euo pipefail

if [[ -n ${XI_DISABLE_MG_WATCH_HOOK:-} ]]; then
  exit 0
fi

mode=${1:?usage: mg-watch.sh session-start|bd-activity}
payload=$(cat 2>/dev/null || printf '{}')

case "$mode" in
session-start) ;;
bd-activity)
  # Defensive re-check of the fragment's `if: "Bash(bd *)"` pre-filter. If a
  # Claude Code release stops honoring `if`, this hook would otherwise run
  # its bd probe on EVERY Bash call. Accept `bd`, `gc bd` (Gas City rig),
  # and an absolute path to bd; reject everything else.
  cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')
  [[ -n $cmd ]] || exit 0
  if ! printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])((gc[[:space:]]+)?bd|[^[:space:]]*/bd)([[:space:]]|$)'; then
    exit 0
  fi
  ;;
*)
  echo "mg-watch.sh: unknown mode '$mode'" >&2
  exit 1
  ;;
esac

target=$(printf '%s' "$payload" | jq -r '.cwd // .workspace_dir // .project_dir // empty')
[[ -n $target ]] || target="${CLAUDE_PROJECT_DIR:-$PWD}"
[[ -d $target ]] || exit 0

for bin in herdr herdr-tui mg bd jq setsid; do
  command -v "$bin" >/dev/null 2>&1 || exit 0
done

# Resolve the repo that owns the bead DB. `.beads/` lives at the git
# toplevel; a bare cwd check would miss when the agent is in a subdirectory.
repo=$(git -C "$target" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$target")
[[ -d "$repo/.beads" ]] || exit 0

# WIP GATE  -  cheapest discriminator first, and no stamp written on the miss
# path so a claim arriving moments later still opens the panel.
wip=$(bd -C "$repo" list --status in_progress --json 2>/dev/null | jq 'length' 2>/dev/null || printf '0')
[[ $wip =~ ^[0-9]+$ ]] || wip=0
((wip > 0)) || exit 0

label="mg-$(basename "$repo")"

# Identify the pane we are running inside: gives us the workspace to scope the
# dedup scan to, and the pane whose death should take the viewer with it.
self_json=$(herdr pane current 2>/dev/null || printf '{}')
self_pane=$(printf '%s' "$self_json" | jq -r '.result.pane.pane_id // empty')
workspace=$(printf '%s' "$self_json" | jq -r '.result.pane.workspace_id // empty')

# Rate-limit guard for the expensive half (herdr scan + spawn). A bead-driving
# turn runs several bd commands back to back; two of them racing inside the
# spawn window would both observe "no pane yet" and both spawn.
stamp_dir="${XDG_RUNTIME_DIR:-/tmp}/mg-watch"
mkdir -p "$stamp_dir" 2>/dev/null || true
stamp_key=$(printf '%s\n%s' "${workspace:-nows}" "$repo" | sha1sum | cut -c1-16)
stamp="$stamp_dir/$stamp_key"
now=$(date +%s)
if [[ -f $stamp ]]; then
  last=$(cat "$stamp" 2>/dev/null || echo 0)
  [[ $last =~ ^[0-9]+$ ]] || last=0
  if ((now - last < 20)); then
    exit 0
  fi
fi

# DEDUP. Scan the non-agent panes of this workspace and compare the `label`
# herdr-tui stamped at launch. Scoped to the workspace so an mg open in
# someone else's workspace does not suppress ours.
if [[ -n $workspace ]]; then
  panes_json=$(herdr pane list --workspace "$workspace" 2>/dev/null || printf '{}')
else
  panes_json=$(herdr pane list 2>/dev/null || printf '{}')
fi

existing=""
while IFS= read -r pane_id; do
  [[ -n $pane_id ]] || continue
  pane_label=$(herdr pane get "$pane_id" 2>/dev/null | jq -r '.result.pane.label // empty')
  if [[ $pane_label == "$label" ]]; then
    existing="$pane_id"
    break
  fi
done < <(printf '%s' "$panes_json" | jq -r '
  .result.panes[]?
  | select(has("agent") | not)
  | .pane_id' | head -25)

if [[ -n $existing ]]; then
  printf '%s' "$now" >"$stamp" 2>/dev/null || true
  exit 0
fi

# Claim the slot BEFORE spawning so a concurrent event bails at the guard.
printf '%s' "$now" >"$stamp" 2>/dev/null || true

# Auto-close policy: idle-reaping is wrong for a viewer, and the previous
# `--auto-close-on-idle 900` in the skill recipe was the same mistake
# lazygit-worktrees already corrected. herdr-tui counts "engagement" as
# pane-focused OR scrolled-up, and a side-panel the human only glances at is
# neither. Pin idle effectively-never and tie the lifetime to the agent pane:
# when this Claude pane goes away, the viewer follows within ~5s.
#
# Closing on "no more in_progress beads" was considered and rejected: the
# human reads the DAG precisely when the agent has just closed the last bead,
# and that predicate would reap the pane at exactly that moment.
close_args=(--auto-close-on-idle 604800)
if [[ -n $self_pane ]]; then
  close_args+=(--auto-close-when "! herdr pane get '$self_pane' >/dev/null 2>&1")
fi

# Bare `mg` with no flush prefix: mardi-gras 0.36 queries the bd CLI live and
# only falls back to reading .beads/issues.jsonl when bd is off PATH.
# Ratio 0.78 leaves the viewer 22% of the row: `--ratio` is the share kept
# by the pane being split, so the new pane gets `1 - ratio`. The
# previous value, 0.35, was commented "keeps the agent's pane dominant" and did
# the exact opposite (viewer got 65%). Re-check with
# `herdr pane resize --pane <id> --direction right --amount 0`, which prints
# the live layout including every split's ratio.
setsid --fork herdr-tui launch \
  --label "$label" \
  --ratio 0.78 \
  "${close_args[@]}" \
  -- mg \
  </dev/null >/dev/null 2>&1 || true

# Nudge the agent on session-start only, so it knows the panel exists and can
# point at the skill if the human asks. bd-activity stays silent: it runs
# async (output is discarded anyway) and the pane appearing is already visible.
if [[ $mode == "session-start" ]]; then
  jq -n --arg r "$repo" --arg l "$label" --arg w "$wip" '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: ("mg-watch: opened `" + $l + "` for " + $r + " (" + $w + " bead(s) in progress). See Skill(mg-watch) for the manual recipe + dedup rules.")
    },
    suppressOutput: true
  }'
fi
