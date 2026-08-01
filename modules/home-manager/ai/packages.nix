{
  flake.modules.homeManager.ai-packages = { pkgs, ... }: {
    home.packages = with pkgs; [
      codemap
      codemap-mcp
      anytype-cli
      # Coding-agent stack (via numtide/llm-agents.nix)
      herdr # terminal multiplexer / runtime for coding agents (`herdr`)
      beads # distributed graph issue tracker / persistent memory (`bd`, `beads`)
      gascity # multi-agent orchestration SDK (`gc`)
      codegraph # semantic code intelligence for AI coding agents (`codegraph`)
      ccusage # cost + token analytics across Claude/Codex/Gemini CLIs
      hunk # TUI diff viewer built for agent-authored changesets
      beads-viewer # graph-aware TUI for the beads issue tracker (`bv`)
      fence # container-free command sandbox (bubblewrap/seatbelt-based)
      spec-kit # GitHub Spec Kit — scaffolds design docs (`specify`); tasks go to beads
      # mempalace  # disabled: pyproject format mismatch, needs pyproject = true upstream
      # mermaid-ascii  # disabled: slow to compile
      # mmdr  # disabled: fetchCargoVendor 403 from crates.io (default python-requests UA blocked by data-access policy)
    ];
  };
}
