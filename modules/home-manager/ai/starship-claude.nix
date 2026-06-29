{
  flake.modules.homeManager.starship-claude =
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
        text = builtins.readFile ./starship-claude.sh;
      };

      starshipClaudeToml = pkgs.writeText "starship-claude.toml" (
        builtins.readFile ./starship-claude.toml
      );
    in
    {
      home.packages = [ starship-claude-script ];

      home.file.".claude/starship.toml".source = starshipClaudeToml;
    };
}
