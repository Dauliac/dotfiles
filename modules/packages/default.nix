{ inputs }:
final: _prev:
let
  codemapPkg = final.callPackage ./codemap.nix { };
  inherit (final.stdenv.hostPlatform) system;
  llmAgentsPkgs = inputs.llm-agents.packages.${system};
  # Unstable buildGoModule (Go 1.26+) — needed by packages whose go.mod
  # requires a toolchain newer than nixos-25.11's Go 1.25.
  unstablePkgs = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
in
{
  codemap = codemapPkg;
  codemap-mcp = codemapPkg.mcp;
  anytype-cli = final.callPackage ./anytype-cli.nix { };
  dust-cli = final.callPackage ./dust-cli { };
  neix = inputs.neix.packages.${system}.default;
  nx = final.callPackage ./nix-wrapper { };
  datadog-pup = final.callPackage ./datadog-pup.nix { };
  spectatui = final.callPackage ./spectatui.nix { };
  # OpenSpec → beads bridge — decomposes an OpenSpec tasks.md into a bead DAG.
  beads-plan = final.callPackage ./beads-plan.nix { };
  # Slack's official platform CLI (github.com/slackapi/slack-cli) — OAuth-session
  # auth via `slack login`, no manual token in sops. Installed as `slack` binary.
  # Requires Go 1.26+ so callPackage is fed unstable's buildGoModule.
  slackapi-cli = final.callPackage ./slackapi-cli.nix {
    buildGoModule = unstablePkgs.buildGoModule;
  };
  # Rust TUI for Jira — keyring-backed credentials (see programs/lazyjira.nix
  # for the sops-nix → secret-service seeding).
  lazyjira = final.callPackage ./lazyjira.nix { };
  # Coding-agent tooling from numtide/llm-agents.nix (daily-updated, uses cache.numtide.com)
  # Terminal-only: no web/GUI review tools (agentsview, crit excluded — both browser UIs).
  # Rust reimplementation of beads; aliased to `pkgs.beads` so all downstream
  # consumers (aliases.nix, home-manager packages, beads-plan) stay put.
  # Upstream renames the binary `bd` → `br`; symlink it back so hard-coded
  # `${pkgs.beads}/bin/bd` callsites and every skill/prompt keep working.
  beads = final.symlinkJoin {
    name = "beads-${llmAgentsPkgs.beads-rust.version}";
    paths = [ llmAgentsPkgs.beads-rust ];
    postBuild = ''
      ln -s $out/bin/br $out/bin/bd
    '';
    inherit (llmAgentsPkgs.beads-rust) version meta;
  };
  inherit (llmAgentsPkgs)
    herdr # multiplexer + agent runtime (TUI)
    codegraph # semantic code intelligence (CLI + MCP)
    ccusage # cost + token analytics (CLI report)
    hunk # TUI diff viewer for agent changesets
    mardi-gras # terminal UI for beads with parade-inspired workflow view (CLI: mg)
    fence # container-free command sandbox (CLI wrapper)
    openspec # delta-based SDD framework (CLI: openspec) — brownfield-first, JSON-first agent contract
    rtk # https://github.com/rtk-ai/rtk — agent runtime toolkit
    ;
}
