{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (
      {
        pkgs,
        config,
        ...
      }:
      let
        # Fetch codemap repo for the skill
        codemapSrc = pkgs.fetchFromGitHub {
          owner = "JordanCoin";
          repo = "codemap";
          rev = "v2.8.3";
          hash = "sha256-2wuRZrcnY2qGMclTOxqAOZOMGctbv38IiSVBlUfsNBI=";
        };
      in
      {
        # Claude Code with MCP servers (via mcps.nix)
        programs.claude-code = {
          enable = true;

          # Presets from mcps.nix (requires mcp-servers-nix overlay)
          mcps = {
            # Git operations
            git.enable = true;
            # Filesystem access
            filesystem = {
              enable = true;
              allowedPaths = [
                "${config.home.homeDirectory}/ghq"
                "${config.home.homeDirectory}/Projects"
                "${config.home.homeDirectory}/Documents"
              ];
            };
            # Web content fetching
            fetch.enable = true;
            # Sequential thinking for complex tasks
            sequential-thinking.enable = true;
            # Note: nixos preset disabled - has input resolution issues
            # Using custom mcpServer instead
          };

          # Custom MCP servers (not in mcps.nix presets)
          mcpServers = {
            # NixOS documentation search (130K+ packages, 22K+ options)
            nixos = {
              type = "stdio";
              command = "uvx";
              args = [ "mcp-nixos" ];
            };

            # Anytype - local knowledge base integration
            # Requires: Anytype desktop app running + API key from Settings > API
            anytype = {
              type = "stdio";
              command = "npx";
              args = [
                "-y"
                "@anyproto/anytype-mcp"
              ];
              env = {
                # Set your API key here or use sops for secrets
                # OPENAPI_MCP_HEADERS = ''{"Authorization":"Bearer YOUR_API_KEY", "Anytype-Version":"2025-05-08"}'';
              };
            };

            # Playwright (Microsoft) - browser automation with Firefox/Chrome/Webkit support
            # Options: --browser chrome|firefox|webkit|msedge
            # Extra caps: --caps vision,pdf,devtools
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
          };
        };

        # Claude Code skills from upstream repos
        home.file.".claude/skills/codemap/SKILL.md".source =
          "${codemapSrc}/.claude/skills/codemap/SKILL.md";
      }
    )
  ];
}
