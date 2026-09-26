{
  flake.modules.homeManager.ai-session-indicator =
    { pkgs, ... }:
    let
      starship-claude-script = pkgs.writeShellApplication {
        name = "starship-claude";
        runtimeInputs = with pkgs; [
          jq
          starship
          coreutils
          procps
          gawk
        ];
        text = builtins.readFile ./indicator.sh;
      };

      starshipClaudeToml = pkgs.writeText "starship-claude.toml" (
        builtins.readFile ./indicator.toml
      );
    in
    {
      home.packages = [ starship-claude-script ];

      home.file.".claude/starship.toml".source = starshipClaudeToml;
    };
}
