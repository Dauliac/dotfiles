{ inputs, ... }:
{
  flake.modules.homeManager.ai = {
    imports = with inputs.self.modules.homeManager; [
      claude-code
      mcp-servers
      ai-packages
      ai-skills
    ];
  };
}
