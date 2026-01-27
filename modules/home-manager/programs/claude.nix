{ pkgs, ... }:
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
  # Claude Code skills from upstream repos
  home.file.".claude/skills/codemap/SKILL.md".source =
    "${codemapSrc}/.claude/skills/codemap/SKILL.md";
}
