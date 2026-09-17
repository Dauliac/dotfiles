{
  # Nix-generated Claude Code rules from each coding-agent tool's own
  # canonical export command. Files land in `~/.claude/rules/*.md`, which
  # Claude auto-loads at every session start (per code.claude.com/docs/en/memory
  # — rules without `paths:` frontmatter load unconditionally).
  #
  # Templates are embedded in the Rust binary (was go:embed in the Go
  # implementation); no network access needed, so nix's default sandbox=on
  # works. When beads bumps in llm-agents.nix, the derivation rebuilds
  # automatically and the symlink re-points — rules refresh with the tool.
  flake.modules.homeManager.ai-workspace-rules =
    { pkgs, ... }:
    {
      # The Go implementation (gastownhall/beads) uses `bd onboard` for
      # the AGENTS.md pointer snippet. `bd prime` would give the full
      # ~80-line workflow context but requires a discoverable .beads/
      # workspace at build time — the sandbox has none, so it exits 0
      # with empty stdout and the derivation trips on `test -s $out`.
      #
      # `bd onboard` is workspace-agnostic. Extract just the content
      # between its `--- BEGIN AGENTS.MD CONTENT ---` sentinels so the
      # rules file is pure actionable markdown, not the surrounding
      # "For GitHub Copilot users:" prose the command adds.
      #
      # Full runtime workflow context still comes via `bd prime` at
      # SessionStart when a workspace is present — the pointer here
      # tells the agent that hook exists.
      home.file.".claude/rules/10-beads.md".source =
        pkgs.runCommand "beads-rules.md" { } ''
          export HOME=$TMPDIR
          cd $TMPDIR
          ${pkgs.beads}/bin/bd onboard \
            | ${pkgs.gnused}/bin/sed -n '/^--- BEGIN AGENTS.MD CONTENT ---$/,/^--- END AGENTS.MD CONTENT ---$/{//!p;}' \
            > $out
          test -s $out
        '';
    };
}
