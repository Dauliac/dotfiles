{
  # mg-watch: auto-spawn a herdr `mg` (mardi-gras) beads side-panel for the
  # repo the agent is driving  -  but only while a bead is actually claimed.
  # Dedup is by the herdr pane `label` (`mg-<repo>`) scoped to the current
  # workspace, so re-firing is a no-op.
  #
  # Two triggers, deliberately asymmetric:
  #
  #   PostToolUse / Bash  -  pre-filtered by `if: "Bash(bd *)"` so the hook
  #     process is not even spawned for non-bd commands. The agent having
  #     just run `bd` through the Bash tool IS the "beads work in progress
  #     by a claude" signal; beads itself cannot tell us (a claim writes
  #     `assignee` from git user.name, so an agent claim and a human claim
  #     are indistinguishable in the DB). Runs `async` so the ~0.6s `bd
  #     list` probe never sits in the agent's critical path.
  #
  #   SessionStart  -  the weaker trigger: no evidence an agent did anything,
  #     so it only reopens a panel for work that was already in flight
  #     (in_progress non-empty) when the session resumed. Not async, because
  #     it returns `additionalContext` telling the agent the panel is open.
  #
  # Timeout is 15s, not 10s like lazygit-worktrees: this hook pays one `bd
  # list --status in_progress` (~0.6s measured) on top of the same
  # per-candidate `herdr pane get` dedup scan. Do not lower it without
  # re-checking hook.sh  -  a killed hook leaves a half-created pane.
  #
  # Motivation: the mg-watch SKILL.md recipe only fired when the agent
  # remembered to invoke it, which is exactly the thing that does not survive
  # a context reset. Hooks are the only lever that does. Same reasoning as
  # lazygit-worktrees, and the two now share their dedup, lifetime, and
  # setsid conventions.
  #
  # Runtime kill-switch (per session):
  #   XI_DISABLE_MG_WATCH_HOOK=1 claude
  #
  # Retraction: if you remove this module, add "mg-watch" to
  # `retiredHookCommands` in workspace/settings.nix so the forward-only
  # deep-merge prunes the stale entries from ~/.claude/settings.json.
  #
  # Order 38- lands after lazygit-worktrees (37-) and before no-em-dash
  # content enforcement (40-).
  #
  # Companion skill: capability/skills/engineering/mg-watch/.
  # See also modules/home-manager/ai/workspace/settings.nix for the
  # deep-merge activation that consumes the fragment.
  flake.modules.homeManager.ai-workspace-mg-watch = { config, ... }: {
    home.file.".claude/hooks/mg-watch.sh" = {
      source = ./mg-watch/hook.sh;
      executable = true;
    };

    home.file.".claude/settings.d/38-mg-watch.json".text = builtins.toJSON {
      hooks.SessionStart = [
        {
          matcher = "*";
          hooks = [
            {
              type = "command";
              command = "bash ${config.home.homeDirectory}/.claude/hooks/mg-watch.sh session-start";
              timeout = 15;
            }
          ];
        }
      ];
      hooks.PostToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              # `if` keeps the hook process from spawning at all unless the
              # command is a bd invocation. hook.sh re-checks the command
              # itself, so the filter degrading to a no-op in some future
              # release costs latency, never correctness.
              "if" = "Bash(bd *)";
              command = "bash ${config.home.homeDirectory}/.claude/hooks/mg-watch.sh bd-activity";
              timeout = 15;
              async = true;
            }
          ];
        }
      ];
    };
  };
}
