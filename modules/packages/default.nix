{ inputs }:
final: _prev:
let
  codemapPkg = final.callPackage ./codemap.nix { };
  inherit (final.stdenv.hostPlatform) system;
  llmAgentsPkgs = inputs.llm-agents.packages.${system};
in
{
  codemap = codemapPkg;
  codemap-mcp = codemapPkg.mcp;
  anytype-cli = final.callPackage ./anytype-cli.nix { };
  mempalace = final.callPackage ./mempalace.nix { };
  neix = inputs.neix.packages.${system}.default;
  nx = final.callPackage ./nix-wrapper { };
  mermaid-ascii = final.callPackage ./mermaid-ascii.nix { };
  mmdr = final.callPackage ./mmdr.nix { };
  datadog-pup = final.callPackage ./datadog-pup.nix { };
  # Coding-agent tooling from numtide/llm-agents.nix (daily-updated, uses cache.numtide.com)
  # Terminal-only: no web/GUI review tools (agentsview, crit excluded — both browser UIs).
  inherit (llmAgentsPkgs)
    herdr # multiplexer + agent runtime (TUI)
    beads # persistent issue-graph memory (CLI: bd) — owns execution state
    gascity # multi-agent orchestration SDK (CLI: gc)
    codegraph # semantic code intelligence (CLI + MCP)
    ccusage # cost + token analytics (CLI report)
    hunk # TUI diff viewer for agent changesets
    beads-viewer # graph-aware TUI for beads (CLI: bv)
    fence # container-free command sandbox (CLI wrapper)
    spec-kit # spec-driven-dev scaffolder (CLI: specify) — owns design artifacts
    ;
}
