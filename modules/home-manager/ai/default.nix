{ inputs, ... }: {
  flake.modules.homeManager.ai = {
    imports = with inputs.self.modules.homeManager; [
      claude-code
      claude-md
      starship-claude
      mcp-servers
      ai-packages
      ai-skills
      beads
    ];
  };
}
