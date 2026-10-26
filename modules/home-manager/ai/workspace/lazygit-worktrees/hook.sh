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
# Dedup: skip the spawn if a pane in the current herdr workspace already has
# `foreground_cwd == <toplevel>` and a `terminal_title_stripped` starting
# with "lazygit".
#
# The spawn is fire-and-forget  -  `herdr-tui launch` daemonizes via setsid,
# so the hook returns well within its timeout.
#
# Runtime kill-switch (per session):
#   XI_DISABLE_LAZYGIT_WORKTREES_HOOK=1 claude
#
# Companion skill: capability/skills/engineering/lazygit-worktrees/SKILL.md.
# Wired via .claude/settings.d/37-lazygit-worktrees.json (see
# lazygit-worktrees.nix).

set -euo pipefail

if [[ -n "${XI_DISABLE_LAZYGIT_WORKTREES_HOOK:-}" ]]; then
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
    [[ -z "$target" ]] && target="${CLAUDE_PROJECT_DIR:-$PWD}"
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

[[ -n "$target" && -d "$target" ]] || exit 0

toplevel=$(git -C "$target" rev-parse --show-toplevel 2>/dev/null || true)
[[ -n "$toplevel" && -d "$toplevel" ]] || exit 0

command -v herdr-tui >/dev/null 2>&1 || exit 0
command -v lazygit  >/dev/null 2>&1 || exit 0
command -v jq      >/dev/null 2>&1 || exit 0

# Dedup against existing panes. Match on foreground_cwd (what the TUI is
# actually scoped to) rather than cwd (drifts with the shell inside the
# pane). Match the title prefix "lazygit" to avoid colliding with a plain
# shell that happens to sit in the same dir.
already=$(herdr pane list 2>/dev/null | jq -r --arg t "$toplevel" '
  .result.panes[]?
  | select((.foreground_cwd // "") == $t
      and ((.terminal_title_stripped // .terminal_title // "") | startswith("lazygit")))
  | .pane_id' | head -1 || true)
if [[ -n "$already" ]]; then
  exit 0
fi

label="lazygit-$(basename "$toplevel")"

# Spawn. `herdr-tui launch` already daemonizes the auto-close watcher via
# setsid; we add `&` + disown so the hook does not wait on the launcher
# itself.
(
  herdr-tui launch \
    --label "$label" \
    --ratio 0.35 \
    --auto-close-on-idle 1800 \
    -- bash -c "cd '$toplevel' && exec lazygit" \
    >/dev/null 2>&1 &
  disown
) || true

# On session-start, nudge the agent with a one-line context so it knows a
# lazygit pane just opened and can reference the skill if the human asks.
# For worktree-create / cwd-changed we stay silent  -  the pane appearing in
# the layout is already visible, extra context would be noise.
if [[ "$mode" == "session-start" ]]; then
  jq -n --arg t "$toplevel" --arg l "$label" '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: ("lazygit-worktrees: opened `" + $l + "` for " + $t + ". See Skill(lazygit-worktrees) for the manual recipe + dedup rules.")
    },
    suppressOutput: true
  }'
fi
