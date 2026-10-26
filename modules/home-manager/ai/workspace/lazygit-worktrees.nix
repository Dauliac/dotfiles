{
  # lazygit-worktrees: auto-spawn a herdr `lazygit` side-panel per git
  # worktree the agent enters  -  one for the main checkout at SessionStart,
  # one more each time `WorktreeCreate` or `CwdChanged` surfaces a fresh
  # worktree path. Dedup is by `foreground_cwd` + `lazygit-` title prefix,
  # so re-firing is a no-op.
  #
  # Motivation: when the agent spawns a nested worktree (via `try
  # worktree`, `herdr worktree create`, or an agent-isolation
  # `.claude/worktrees/<slug>`), there is no live diff viewer scoped to
  # the new path. The human loses sight of what the agent is actually
  # editing. Rather than teaching the agent to open lazygit manually
  # every time, we let the Claude Code hook layer do it  -  hooks are the
  # only lever that survives agent context resets.
  #
  # The three modes (session-start / worktree-create / cwd-changed) are
  # documented inside the hook script itself.
  #
  # Runtime kill-switch (per session):
  #   XI_DISABLE_LAZYGIT_WORKTREES_HOOK=1 claude
  #
  # Retraction: if you remove this module, add "lazygit-worktrees" to
  # `retiredHookCommands` in workspace/settings.nix so the forward-only
  # deep-merge prunes the stale entries from ~/.claude/settings.json.
  #
  # Order 37- lands after jira-mr-coherence (35-) and before no-em-dash
  # content enforcement (40-).
  #
  # Companion skill: capability/skills/engineering/lazygit-worktrees/.
  # See also modules/home-manager/ai/workspace/settings.nix for the
  # deep-merge activation that consumes the fragment.
  flake.modules.homeManager.ai-workspace-lazygit-worktrees =
    { config, ... }:
    {
      home.file.".claude/hooks/lazygit-worktrees.sh" = {
        source = ./lazygit-worktrees/hook.sh;
        executable = true;
      };

      home.file.".claude/settings.d/37-lazygit-worktrees.json".text = builtins.toJSON {
        hooks.SessionStart = [
          {
            matcher = "*";
            hooks = [
              {
                type = "command";
                command = "bash ${config.home.homeDirectory}/.claude/hooks/lazygit-worktrees.sh session-start";
                timeout = 5;
              }
            ];
          }
        ];
        hooks.WorktreeCreate = [
          {
            matcher = "*";
            hooks = [
              {
                type = "command";
                command = "bash ${config.home.homeDirectory}/.claude/hooks/lazygit-worktrees.sh worktree-create";
                timeout = 5;
              }
            ];
          }
        ];
        hooks.CwdChanged = [
          {
            matcher = "*";
            hooks = [
              {
                type = "command";
                command = "bash ${config.home.homeDirectory}/.claude/hooks/lazygit-worktrees.sh cwd-changed";
                timeout = 5;
              }
            ];
          }
        ];
      };
    };
}
