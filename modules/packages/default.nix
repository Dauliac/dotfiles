{ inputs }:
final: _prev:
let
  codemapPkg = final.callPackage ./codemap.nix { };
  statewrightPkgs = final.callPackage ./statewright.nix { };
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
  # anyr — Anytype Toolbox CLI (stevelr/anytype). Pulled from upstream flake
  # so we don't own the Rust workspace hash bumps. See flake.nix input
  # `anytype-toolbox`. Replaces the older epheo/anytype-cli Go binary.
  anyr = inputs.anytype-toolbox.packages.${system}.default;
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
  # Statewright workflow-layer for coding agents. Gateway is a prebuilt
  # release binary (linux amd64); sw-agent + TUI build from source via
  # rustPlatform.buildRustPackage. See modules/packages/statewright.nix and
  # docs/statewright/cheatsheet.md §0, §10.
  inherit (statewrightPkgs)
    statewright-gateway
    sw-agent
    statewright-tui
    ;
  # Declarative herdr plugins built from GitHub sources — see openspec
  # change herdr-plugins-declarative. Exposes pkgs.herdrPlugins.{auto-title,agent-quota}
  # for `programs.herdr.plugins.<name>.source = pkgs.herdrPlugins.<name>`.
  # agent-quota needs Rust 1.95+; feed unstable's rustPlatform per the
  # slackapi-cli precedent above.
  herdrPlugins = final.callPackage ./herdr-plugins {
    rustPlatform = unstablePkgs.rustPlatform;
  };
  # Coding-agent tooling from numtide/llm-agents.nix (daily-updated, uses cache.numtide.com)
  # Terminal-only: no web/GUI review tools (agentsview, crit excluded — both browser UIs).
  # `beads` is the Go implementation (gastownhall/beads, binary `bd`, Dolt-backed) —
  # see openspec change beads-go-migration-and-dolt-caps for the switch from
  # the earlier Rust `beads-rust` (br, SQLite) which is no longer aliased.
  inherit (llmAgentsPkgs)
    beads # distributed graph issue tracker for AI-agent memory (CLI: bd, Dolt backend)
    beads-viewer # graph-aware TUI for beads (CLI: bv)
    # Dolt is exposed as pkgs.dolt so the dolt-beads systemd user service
    # (modules/home-manager/services/dolt-beads.nix) can reach a Dolt >= 2.0.3
    # (fix for auto-GC gating bug dolthub/dolt#10944). llm-agents.nix pins
    # 2.3.2; nixpkgs 25.11 stock is 1.x, which would silently regress the fix.
    dolt
    herdr # multiplexer + agent runtime (TUI)
    codegraph # semantic code intelligence (CLI + MCP)
    ccusage # cost + token analytics (CLI report)
    hunk # TUI diff viewer for agent changesets
    fence # container-free command sandbox (CLI wrapper)
    mardi-gras # TUI for beads issue tracker reading .beads/issues.jsonl (CLI: mg) — coexists with beads-viewer per openspec change beads-mg-tui-integration
    openspec # delta-based SDD framework (CLI: openspec) — brownfield-first, JSON-first agent contract
    rtk # https://github.com/rtk-ai/rtk — agent runtime toolkit
    ;
}
