{
  # Reuse-first scratch script library for Claude and adjacent agents.
  # See modules/home-manager/ai/skills/scratch-scripts/SKILL.md for the
  # user-facing protocol.
  #
  # Ships the pieces (dir + hook script + skill), and contributes a
  # SessionStart hook fragment consumed by the claude-settings merge
  # activation (modules/home-manager/ai/claude-settings.nix) — the merge
  # appends this to whatever's already in ~/.claude/settings.json without
  # clobbering Claude's or codegraph's runtime writes.
  flake.modules.homeManager.ai-capability-scratch =
    {
      lib,
      config,
      ...
    }:
    {
      # Ensure the cross-project scratch directory exists so agents can
      # write to it without a mkdir dance.
      home.activation.claudeScratchDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "''${XDG_CACHE_HOME:-$HOME/.cache}/claude/scratch"
      '';

      # Ship the SessionStart index hook.
      home.file.".claude/hooks/scratch-index.sh" = {
        source = ./scratch/index.sh;
        executable = true;
      };

      # Contribute the hook wiring as a settings fragment. The
      # claude-settings-merge activation deep-merges every fragment under
      # ~/.claude/settings.d/*.json onto ~/.claude/settings.json, appending
      # to hooks arrays instead of replacing them, so this coexists with
      # herdr-agent-state.sh and any other SessionStart hooks installed by
      # Claude, codegraph, or the mm-* CLIs.
      home.file.".claude/settings.d/10-scratch.json".text = builtins.toJSON {
        hooks.SessionStart = [
          {
            matcher = "*";
            hooks = [
              {
                type = "command";
                command = "bash ${config.home.homeDirectory}/.claude/hooks/scratch-index.sh";
                timeout = 3;
              }
            ];
          }
        ];
      };
    };
}
