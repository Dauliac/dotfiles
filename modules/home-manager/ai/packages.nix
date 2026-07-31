{
  flake.modules.homeManager.ai-packages =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        codemap
        codemap-mcp
        anytype-cli
        # Coding-agent stack (via numtide/llm-agents.nix)
        herdr # terminal multiplexer / runtime for coding agents (`herdr`)
        beads # distributed graph issue tracker / persistent memory (`bd`, `beads`)
        gascity # multi-agent orchestration SDK (`gc`)
        # mempalace  # disabled: pyproject format mismatch, needs pyproject = true upstream
        # mermaid-ascii  # disabled: slow to compile
        # mmdr  # disabled: fetchCargoVendor 403 from crates.io (default python-requests UA blocked by data-access policy)
      ];
    };
}
