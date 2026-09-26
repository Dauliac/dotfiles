{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  fetchzip,
  autoPatchelfHook,
  unzip,
  rustPlatform,
  pkg-config,
  openssl,
}:
# Statewright — MCP workflow-layer for coding agents.
#
# Two related derivations sharing the same upstream release tag
# `gateway-v1.1.3` (2026-09 vintage). See docs/statewright/cheatsheet.md
# §0, §10, §12 for the authoritative binary catalog and build recipe.
#
# `statewright-gateway`  — prebuilt Linux amd64 release zip; upstream ships
#                          binaries for {linux,darwin} x {amd64,arm64}.
# `sw-agent` + `statewright-tui` — built from source via cargo (the release
#                          bundles are gateway-only, so the CLI + TUI must
#                          come from `rustPlatform.buildRustPackage`).
#
# Workspace edition = "2024" ⇒ rustc ≥ 1.85. No upstream `rust-toolchain.toml`;
# nixpkgs-25.11 rustc satisfies this.
#
# Bump protocol: change `version` + `gatewayTag`, set both `hash` values to
# `lib.fakeHash`, run `nix build .#statewright-gateway .#sw-agent`, then
# paste the `got:` hash from each error back in. See cheatsheet §10.
let
  # Shared source pin. Gateway release tag also fixes the workspace commit
  # for the source build so binaries stay in lockstep.
  version = "1.1.3";
  gatewayTag = "gateway-v${version}";
  sourceRev = gatewayTag;

  # Prebuilt gateway release zip (linux/amd64). Upstream also ships arm64;
  # add a platform switch if aarch64-linux support becomes necessary.
  gatewaySrc = fetchzip {
    url = "https://github.com/statewright/statewright/releases/download/${gatewayTag}/statewright-gateway_linux_amd64.zip";
    hash = "sha256-WZwTQ7rHjFp7hGPYqjV1f/1MgfiQqI5h2tfbU5K+7ho=";
    stripRoot = false;
  };

  # Workspace source for sw-agent + TUI.
  workspaceSrc = fetchFromGitHub {
    owner = "statewright";
    repo = "statewright";
    rev = sourceRev;
    hash = "sha256-9h4zdF2T9/KN5ijw9E/pjehexd1cDuyjwebMRYLPAoo=";
  };

  statewright-gateway = stdenv.mkDerivation {
    pname = "statewright-gateway";
    inherit version;

    src = gatewaySrc;

    nativeBuildInputs = [
      unzip
      autoPatchelfHook
    ];

    # Prebuilt binary is dynamically linked against openssl 3 + libgcc_s.
    buildInputs = [
      openssl
      stdenv.cc.cc.lib
    ];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      # Release zip ships the binary as `statewright-gateway_linux_amd64`;
      # rename to the canonical `statewright-gateway` on install.
      install -Dm755 statewright-gateway_linux_amd64 $out/bin/statewright-gateway
      runHook postInstall
    '';

    meta = with lib; {
      description = "MCP proxy + hook HTTP server enforcing per-state guardrails at the tool-call layer (statewright workflow-layer gateway)";
      homepage = "https://github.com/statewright/statewright";
      license = with licenses; [
        asl20 # workspace
        # FSL-1.1-ALv2 for the gateway crate (not in nixpkgs licenses set)
      ];
      platforms = [ "x86_64-linux" ];
      mainProgram = "statewright-gateway";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    };
  };

  # sw-agent + statewright (TUI) share the same source tree; buildRustPackage
  # builds the whole workspace and we install one binary per derivation. This
  # matches how nixpkgs handles multi-binary Rust workspaces where the
  # binaries have distinct semantics but share dependencies.
  mkWorkspaceBin =
    {
      pname,
      binName,
      description,
    }:
    rustPlatform.buildRustPackage {
      inherit pname version;
      src = workspaceSrc;

      # Upstream ships a workspace Cargo.lock; use it verbatim so the
      # vendored dependency graph matches what upstream tests against.
      cargoLock = {
        lockFile = "${workspaceSrc}/Cargo.lock";
      };
      # NOTE: cargoLock requires the Cargo.lock to be present at
      # workspaceSrc's top level (it is, per cheatsheet §10.2).

      nativeBuildInputs = [ pkg-config ];
      # `axum`/`reqwest` typically pull `openssl-sys`; keep it available.
      # Cheatsheet §10.2 flags this as UNVERIFIED — if the build succeeds
      # without openssl, we can drop it.
      buildInputs = [ openssl ];

      # Only install the binary that owns this derivation; the workspace
      # produces three (gateway, sw-agent, statewright TUI) — gateway comes
      # from the release zip.
      cargoBuildFlags = [
        "--bin"
        binName
      ];
      cargoTestFlags = [
        "--bin"
        binName
      ];

      # Upstream tests hit Ollama + filesystem fixtures; skip in the sandbox.
      doCheck = false;

      meta = with lib; {
        inherit description;
        homepage = "https://github.com/statewright/statewright";
        license = licenses.asl20;
        platforms = platforms.unix;
        mainProgram = binName;
      };
    };

  sw-agent = mkWorkspaceBin {
    pname = "sw-agent";
    binName = "sw-agent";
    description = "Statewright direct-to-Ollama constrained agent executor; streams JSONL events for TUI/gateway integration";
  };

  statewright-tui = mkWorkspaceBin {
    pname = "statewright";
    binName = "statewright";
    description = "Statewright Ratatui TUI — spawns sw-agent and renders its JSONL event stream";
  };
in
{
  inherit statewright-gateway sw-agent statewright-tui;
}
