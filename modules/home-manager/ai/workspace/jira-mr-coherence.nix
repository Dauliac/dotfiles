{
  # jira-mr-coherence: Claude-native enforcement of the triplet invariant
  # (Jira ticket, GitLab MR, status reflects reality) via four hooks
  # sharing one script. Scope: GT and PLAT project prefixes only.
  #
  # Motivation: the agent repeatedly creates a Jira workitem without
  # transitioning it to In Progress, or opens an MR without linking it to
  # the paired ticket. These are habit drifts that a soft "please
  # remember" instruction does not fix. Hooks are the only lever that
  # survives agent context resets, per the Claude Code permissions
  # docs: "Permission rules are enforced by Claude Code, not by the
  # model."
  #
  # The four modes (anchor / gate / record / drift) are documented in
  # the hook script itself. Summary:
  #   anchor : UserPromptSubmit  - inject skill reminder on GT/PLAT ids
  #   gate   : PreToolUse Bash   - ask-prompt before sensitive twg/glab;
  #                                hard DENY on `twg jira workitem create`
  #                                when --type is not Sub-task and
  #                                --field "Team=..." is missing
  #                                (customfield_10600 is the team routing
  #                                anchor; tickets without it hang off
  #                                every team board).
  #   record : PostToolUse Bash  - bump per-session pending counters
  #                                (transitions, links, team-sets)
  #   drift  : Stop              - block end-of-turn if counters > 0
  #
  # Runtime kill-switch (per session):
  #   XI_DISABLE_JIRA_MR_COHERENCE_HOOK=1 claude
  #
  # Retraction: if you remove this module, add "jira-mr-coherence" to
  # `retiredHookCommands` in workspace/settings.nix so the forward-only
  # deep-merge prunes the stale entries from ~/.claude/settings.json.
  #
  # Order 35- lands after skill-compliance (30-) and before no-em-dash
  # content enforcement (40-).
  #
  # See also modules/home-manager/ai/workspace/settings.nix for the
  # deep-merge activation that consumes the fragment.
  flake.modules.homeManager.ai-workspace-jira-mr-coherence =
    { config, ... }:
    {
      home.file.".claude/hooks/jira-mr-coherence.sh" = {
        source = ./jira-mr-coherence/hook.sh;
        executable = true;
      };

      home.file.".claude/settings.d/35-jira-mr-coherence.json".text = builtins.toJSON {
        hooks.UserPromptSubmit = [
          {
            matcher = "*";
            hooks = [
              {
                type = "command";
                command = "bash ${config.home.homeDirectory}/.claude/hooks/jira-mr-coherence.sh anchor";
                timeout = 3;
              }
            ];
          }
        ];
        hooks.PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "bash ${config.home.homeDirectory}/.claude/hooks/jira-mr-coherence.sh gate";
                timeout = 5;
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
                command = "bash ${config.home.homeDirectory}/.claude/hooks/jira-mr-coherence.sh record";
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
                command = "bash ${config.home.homeDirectory}/.claude/hooks/jira-mr-coherence.sh drift";
                timeout = 5;
              }
            ];
          }
        ];
      };
    };
}
