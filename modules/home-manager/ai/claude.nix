{
  flake.modules.homeManager.claude-code = {
    programs.claude-code = {
      enable = true;
      settings.permissions.deny = [
        "mcp__claude_ai_Context7__*"
        "mcp__claude_ai_Excalidraw__*"
      ];
    };
  };
}
