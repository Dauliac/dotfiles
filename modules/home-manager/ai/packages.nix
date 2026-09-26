{
  flake.modules.homeManager.ai-packages = { pkgs, ... }: {
    home.packages = with pkgs; [
      codemap
      codemap-mcp
      anyr # Anytype Toolbox CLI (stevelr/anytype) — spaces/objects/files/chats + Markdown round-trip + backups
      # anytype-heart — bundles anytypeHelper, the CLI-server binary anyr spawns
      # when ANYTYPE_CLI_BIN is set. Enables anyr's gRPC mode (space home page,
      # sidebar pins, type.--add-property, count-archived, sharing controls) —
      # everything the plain HTTP REST endpoint at :31009 does NOT expose.
      # Runtime constraint: two anytype-heart processes can't share an account,
      # so `anyr init-cli` requires the desktop app to be closed first.
      anytype-heart
      dust-cli # Dust agents CLI — https://docs.dust.tt/docs/developer-platform/dust-cli/dust-cli
      # Coding-agent stack (via numtide/llm-agents.nix)
      herdr # terminal multiplexer / runtime for coding agents (`herdr`)
      beads # distributed graph issue tracker / persistent memory (`bd`, `beads`)
      codegraph # semantic code intelligence for AI coding agents (`codegraph`)
      ccusage # cost + token analytics across Claude/Codex/Gemini CLIs
      hunk # TUI diff viewer built for agent-authored changesets
      beads-viewer # graph-aware TUI for the shared Dolt-backed beads DB (`bv`)
      mardi-gras # terminal UI for the beads issue tracker (CLI: mg) — reads .beads/issues.jsonl; coexists with beads-viewer per openspec change beads-mg-tui-integration
      fence # container-free command sandbox (bubblewrap/seatbelt-based)
      openspec # delta-based SDD framework — brownfield-first, `openspec new/archive`
      beads-plan # OpenSpec → beads bridge (decomposes tasks.md into a bead DAG)
    ];

    home.sessionVariables = {
      ANYTYPE_CLI_BIN = "${pkgs.anytype-heart}/bin/anytypeHelper";
    };
  };
}
