{ inputs, ... }:
{
  # Capability bounded context — the agent's reach: which runtimes it can
  # invoke, which MCP servers it can call, which skills it can wield, which
  # scratch space it can persist to, and the permission ACL that lets
  # capabilities register their needs with the workspace's settings.
  flake.modules.homeManager.ai-capability = {
    imports = with inputs.self.modules.homeManager; [
      ai-capability-runtime-claude
      ai-capability-mcp
      ai-capability-skills
      ai-capability-scratch
      ai-capability-permissions
      ai-capability-statewright
    ];
  };
}
