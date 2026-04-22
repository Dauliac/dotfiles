let
  skillsDir = ./skills;
in
{
  flake.modules.homeManager.ai-skills =
    { pkgs, ... }:
    let
      codemapSrc = pkgs.fetchFromGitHub {
        owner = "JordanCoin";
        repo = "codemap";
        rev = "v2.8.3";
        hash = "sha256-2wuRZrcnY2qGMclTOxqAOZOMGctbv38IiSVBlUfsNBI=";
      };
    in
    {
      home.file = {
        ".claude/skills/codemap/SKILL.md".source = "${codemapSrc}/.claude/skills/codemap/SKILL.md";
        ".claude/skills/rodin/SKILL.md".source = "${skillsDir}/rodin/SKILL.md";
        ".claude/skills/diagram/SKILL.md".source = "${skillsDir}/diagram/SKILL.md";
      };
    };
}
