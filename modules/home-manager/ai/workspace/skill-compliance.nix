{
  # Skill-compliance hook — a UserPromptSubmit hook layered on top of the
  # enterprise "MANDATORY SKILL ACTIVATION SEQUENCE" hook that ships via
  # remote-settings.json (server-pushed, not editable from nix). The
  # upstream hook already asks for a per-skill YES/NO enumeration but
  # tolerates "No skills needed" as a one-line collapse; in practice
  # agents use that shortcut to skip word-match hits (herdr-run vs
  # `cargo build` being the concrete failure that motivated this).
  #
  # This module ships two things:
  #   1. A script at ~/.claude/hooks/skill-compliance.sh printing the
  #      compliance addendum (word-match self-check, forbidden phrases).
  #   2. A settings.json fragment wiring it as UserPromptSubmit, merged
  #      onto ~/.claude/settings.json by ai-workspace-settings' activation.
  #
  # Runtime kill-switch (per session):
  #   XI_DISABLE_SKILL_COMPLIANCE_HOOK=1 claude
  #
  # See also modules/home-manager/ai/workspace/settings.nix for the
  # deep-merge activation that consumes the fragment.
  flake.modules.homeManager.ai-workspace-skill-compliance =
    { config, ... }:
    {
      home.file.".claude/hooks/skill-compliance.sh" = {
        source = ./skill-compliance/hook.sh;
        executable = true;
      };

      # Order 30- lands after nix-shipped tool perms (20-29) and before
      # skill-only perms (50+). Runs alongside — not replacing — the
      # enterprise UserPromptSubmit hook and the codegraph hook.
      home.file.".claude/settings.d/30-skill-compliance.json".text = builtins.toJSON {
        hooks.UserPromptSubmit = [
          {
            matcher = "*";
            hooks = [
              {
                type = "command";
                command = "bash ${config.home.homeDirectory}/.claude/hooks/skill-compliance.sh";
                timeout = 3;
              }
            ];
          }
        ];
      };
    };
}
