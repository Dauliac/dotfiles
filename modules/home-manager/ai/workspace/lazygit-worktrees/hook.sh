#!/usr/bin/env bash
# lazygit-worktrees: spawn one `lazygit` side-panel per active git worktree.
#
# Three modes sharing one spawn routine:
#
#   session-start   : SessionStart. Payload has `cwd` (or $CLAUDE_PROJECT_DIR).
#                     If it is a git worktree, spawn lazygit for its toplevel.
#   worktree-create : WorktreeCreate. Payload has the new worktree path
#                     (`.worktree.path` / `.path` / `.result.worktree.path`  -
#                     we probe each). Spawn lazygit for it.
#   cwd-changed     : CwdChanged. Payload has `.cwd`. If the new cwd is
#                     inside a different worktree than the agent pane's
#                     foreground_cwd, spawn lazygit for the new toplevel.
#
# Dedup (see DEDUP below): `herdr pane get <id>` on the non-agent panes of the
# CURRENT workspace, matching the `label` field. Do NOT match on
# `terminal_title*`  -  `herdr-tui launch` always runs the command through an
# `exec sh -c "$(printf '%s' <base64> | base64 -d)"` wrapper, so the title is
# that wrapper, never "lazygit". Title matching silently never fires, which is
# how this hook used to leak one new split per CwdChanged event.
#
# `label` is only exposed by `herdr pane get`, not by `herdr pane list`, hence
# the per-candidate get. Candidates are cheap: agent panes are filtered out by
# `has("agent")`, so a workspace yields a handful at most.
#
# The spawn runs under `setsid --fork` so it survives the hook process group
# being torn down when the hook returns (a backgrounded `&` + disown does NOT
#  -  it stays in the hook's process group and gets killed mid-launch, which
# leaves a blank half-created pane behind).
#
# Runtime kill-switch (per session):
#   XI_DISABLE_LAZYGIT_WORKTREES_HOOK=1 claude
#
# Companion skill: capability/skills/engineering/lazygit-worktrees/SKILL.md.
# Wired via .claude/settings.d/37-lazygit-worktrees.json (see
# lazygit-worktrees.nix).

set -euo pipefail

if [[ -n ${XI_DISABLE_LAZYGIT_WORKTREES_HOOK:-} ]]; then
  exit 0
fi

mode=${1:?usage: lazygit-worktrees.sh session-start|worktree-create|cwd-changed}
payload=$(cat 2>/dev/null || printf '{}')

# Resolve the target path per mode. Each extractor must be defensive  -  hook
# payload shapes drift across Claude Code releases, so we probe several
# candidate fields and fall back to env vars where sensible.
target=""
case "$mode" in
session-start)
  target=$(printf '%s' "$payload" | jq -r '.cwd // .workspace_dir // .project_dir // empty')
  [[ -z $target ]] && target="${CLAUDE_PROJECT_DIR:-$PWD}"
  ;;
worktree-create)
  target=$(printf '%s' "$payload" | jq -r '
      .worktree.path
      // .worktree_path
      // .path
      // .result.worktree.path
      // .tool_response.path
      // empty')
  ;;
cwd-changed)
  target=$(printf '%s' "$payload" | jq -r '.cwd // .new_cwd // .to // empty')
  ;;
*)
  echo "lazygit-worktrees.sh: unknown mode '$mode'" >&2
  exit 1
  ;;
esac

[[ -n $target && -d $target ]] || exit 0

toplevel=$(git -C "$target" rev-parse --show-toplevel 2>/dev/null || true)
[[ -n $toplevel && -d $toplevel ]] || exit 0

for bin in herdr herdr-tui lazygit jq setsid; do
  command -v "$bin" >/dev/null 2>&1 || exit 0
done

label="lazygit-$(basename "$toplevel")"

# Identify the pane we are running inside: gives us the workspace to scope the
# dedup scan to, and the pane whose death should take the viewer with it.
self_json=$(herdr pane current 2>/dev/null || printf '{}')
self_pane=$(printf '%s' "$self_json" | jq -r '.result.pane.pane_id // empty')
workspace=$(printf '%s' "$self_json" | jq -r '.result.pane.workspace_id // empty')

# Rate-limit guard. CwdChanged fires on every `cd` the agent performs, which
# can be several per turn. Two events racing inside the spawn window would both
# observe "no pane yet" and both spawn. A short-TTL stamp collapses the burst;
# it is refreshed on the dedup-hit path too, so steady-state CwdChanged costs
# one stat instead of a full herdr scan.
stamp_dir="${XDG_RUNTIME_DIR:-/tmp}/lazygit-worktrees"
mkdir -p "$stamp_dir" 2>/dev/null || true
stamp_key=$(printf '%s\n%s' "${workspace:-nows}" "$toplevel" | sha1sum | cut -c1-16)
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
# herdr-tui stamped at launch (`herdr pane rename <pane> <label>`). Scoped to
# the workspace so a lazygit open in someone else's workspace does not suppress
# ours. Matching on label rather than foreground_cwd keeps working if lazygit
# is navigated to a sibling directory.
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

# Auto-close policy: idle-reaping is wrong for a viewer. herdr-tui counts
# "engagement" as pane-focused OR scrolled-up, and a side-panel the human only
# glances at is neither  -  the default 1800s idle silently killed the split
# mid-session. Pin idle effectively-never and tie the lifetime to the agent
# pane instead: when this Claude pane goes away, the viewer follows within ~5s.
close_args=(--auto-close-on-idle 604800)
if [[ -n $self_pane ]]; then
  close_args+=(--auto-close-when "! herdr pane get '$self_pane' >/dev/null 2>&1")
fi

# `lazygit -p <path>` instead of `bash -c "cd <path> && exec lazygit"`: one
# process, no shell wrapper, and the pane's foreground_cwd lands on the
# worktree toplevel directly.
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
  -- lazygit -p "$toplevel" \
  </dev/null >/dev/null 2>&1 || true

# On session-start, nudge the agent with a one-line context so it knows a
# lazygit pane just opened and can reference the skill if the human asks.
# For worktree-create / cwd-changed we stay silent  -  the pane appearing in
# the layout is already visible, extra context would be noise.
if [[ $mode == "session-start" ]]; then
  jq -n --arg t "$toplevel" --arg l "$label" '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: ("lazygit-worktrees: opened `" + $l + "` for " + $t + ". See Skill(lazygit-worktrees) for the manual recipe + dedup rules.")
    },
    suppressOutput: true
  }'
fi
