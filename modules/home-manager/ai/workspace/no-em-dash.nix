{
  # no-em-dash: hard-constraint hook that strips U+2014 from every byte
  # leaving a Claude Code session via a tool call (Bash, Write, Edit,
  # NotebookEdit, mcp__*), and forces a redo when U+2014 appears in the
  # assistant's final chat message.
  #
  # Why a hook and not the existing no-em-dash skill: the skill is a soft
  # constraint (the model must remember to invoke it). Per the Claude Code
  # permissions docs, "Permission rules are enforced by Claude Code, not
  # by the model. Instructions in your prompt or CLAUDE.md shape what
  # Claude tries to do, but they don't change what Claude Code allows."
  # PreToolUse hooks with `hookSpecificOutput.updatedInput` are the one
  # documented lever for hard content enforcement on tool arguments.
  #
  # Full primary-source rationale (mechanism enumeration, why permission
  # rules cannot do this, why chat text remains a nag-only gap):
  #   ~/.claude/research/hard-constraints-on-claude-output.md
  #
  # This module ships two things:
  #   1. A script at ~/.claude/hooks/no-em-dash.sh with pretooluse|stop
  #      modes.
  #   2. A settings.json fragment wiring it as PreToolUse (matcher
  #      "Bash|Write|Edit|NotebookEdit|mcp__.*") and Stop, merged onto
  #      ~/.claude/settings.json by ai-workspace-settings' activation.
  #
  # Runtime kill-switch (per session):
  #   XI_DISABLE_NO_EM_DASH_HOOK=1 claude
  #
  # Retraction: if you remove this module, add the substring "no-em-dash"
  # to `retiredHookCommands` in workspace/settings.nix so the forward-only
  # deep-merge prunes the stale entries from ~/.claude/settings.json.
  #
  # See also modules/home-manager/ai/workspace/settings.nix for the
  # deep-merge activation that consumes the fragment.
  flake.modules.homeManager.ai-workspace-no-em-dash =
    { config, ... }:
    {
      home.file.".claude/hooks/no-em-dash.sh" = {
        source = ./no-em-dash/hook.sh;
        executable = true;
      };

      # Order 40- lands after skill-compliance (30-) and before skill-only
      # perms (50+). Runs alongside every other configured hook on those
      # events; the harness fans out to all of them.
      home.file.".claude/settings.d/40-no-em-dash.json".text = builtins.toJSON {
        hooks.PreToolUse = [
          {
            matcher = "Bash|Write|Edit|NotebookEdit|mcp__.*";
            hooks = [
              {
                type = "command";
                command = "bash ${config.home.homeDirectory}/.claude/hooks/no-em-dash.sh pretooluse";
                timeout = 5;
              }
            ];
          }
        ];
        hooks.Stop = [
          {
            hooks = [
              {
                type = "command";
                command = "bash ${config.home.homeDirectory}/.claude/hooks/no-em-dash.sh stop";
                timeout = 5;
              }
            ];
          }
        ];
      };
    };
}
