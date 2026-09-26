{ inputs, ... }:
{
  # Workspace bounded context — the agent's beliefs about *this* project and
  # user: instructions, rules, settings. Aggregates every leaf that shapes
  # what the agent knows before it acts.
  flake.modules.homeManager.ai-workspace = {
    imports = with inputs.self.modules.homeManager; [
      ai-workspace-instructions
      ai-workspace-rules
      ai-workspace-settings
      ai-workspace-skill-compliance
      ai-workspace-no-em-dash
    ];
  };
}
