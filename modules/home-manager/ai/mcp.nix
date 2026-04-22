{
  flake.modules.homeManager.mcp-servers =
    { config, ... }:
    {
      programs.claude-code = {
        mcps = {
          git.enable = true;
          filesystem = {
            enable = true;
            allowedPaths = [
              "${config.home.homeDirectory}/ghq"
              "${config.home.homeDirectory}/Projects"
              "${config.home.homeDirectory}/Documents"
            ];
          };
          fetch.enable = true;
        };

        mcpServers = {
          nixos = {
            type = "stdio";
            command = "uvx";
            args = [ "mcp-nixos" ];
          };

          anytype = {
            type = "stdio";
            command = "npx";
            args = [
              "-y"
              "@anyproto/anytype-mcp"
            ];
            env = { };
          };

          playwright = {
            type = "stdio";
            command = "npx";
            args = [
              "-y"
              "@playwright/mcp@latest"
              "--browser"
              "firefox"
            ];
          };

          mempalace = {
            type = "stdio";
            command = "python";
            args = [
              "-m"
              "mempalace.mcp_server"
              "--palace"
              "${config.home.homeDirectory}/.mempalace"
            ];
          };

          lsp = {
            type = "stdio";
            command = "npx";
            args = [
              "-y"
              "lsp-mcp@latest"
            ];
          };
        };
      };
    };
}
