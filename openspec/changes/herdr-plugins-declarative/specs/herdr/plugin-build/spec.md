## Purpose

Defines the Nix derivation helper that translates a herdr plugin GitHub repository into a self-contained plugin directory suitable for consumption by kevinpita's `programs.herdr.plugins.<name>.source` option. This is the seam that lets us honor herdr's `[[build]]` manifest section without ever running `herdr plugin install` on the host — build in the sandbox, hand a pre-built directory to `herdr plugin link`.

## ADDED Requirements

### Requirement: `pkgs.buildHerdrPlugin` helper

A flake-parts perSystem module SHALL expose `pkgs.buildHerdrPlugin` as a function with the signature `{ pname, version, src, id, nativeBuildInputs ? [], buildPhase, installExtra ? "" }`. The helper SHALL produce a derivation whose `$out/share/herdr-plugins/<id>/` directory contains, at minimum, the plugin's `herdr-plugin.toml` manifest copied from the source tree and any built artifacts placed by `installExtra`. The helper MUST NOT require or invoke network access at build time — all sources come from `src`, which is expected to be a `fetchFromGitHub`-produced fixed-output derivation.

#### Scenario: minimal plugin (manifest only, no build)

- **WHEN** `pkgs.buildHerdrPlugin { pname = "example"; version = "0.1.0"; src = ./minimal-plugin; id = "example.minimal"; buildPhase = "true"; }` is evaluated on a source tree containing only `herdr-plugin.toml`
- **THEN** `nix build` succeeds and `$out/share/herdr-plugins/example.minimal/herdr-plugin.toml` exists byte-identical to the source

#### Scenario: plugin with binary artifact

- **WHEN** `buildHerdrPlugin` is invoked with `buildPhase = "go build -o hello ./cmd/hello"` and `installExtra = "cp hello \"$dst/\""`
- **THEN** the resulting `$out/share/herdr-plugins/<id>/` contains both `herdr-plugin.toml` and the `hello` binary, and the binary's rpath is patched (via nixpkgs' `autoPatchelfHook` transitively) so it runs on the host

### Requirement: build-input passthrough

The helper SHALL propagate `nativeBuildInputs` verbatim to the underlying `stdenv.mkDerivation`, so callers can add `go`, `cargo`, `nodejs`, `bun`, or any other toolchain declared in the plugin's manifest `[[build]]` section. The helper MUST NOT hardcode a language runtime — Go and Rust plugins are two different callers, each responsible for their own toolchain declaration.

#### Scenario: Go plugin

- **WHEN** a caller passes `nativeBuildInputs = [ pkgs.go ]` alongside `buildPhase = "go build ..."`
- **THEN** `go` is on `$PATH` during `buildPhase` and the compile succeeds without further wiring

#### Scenario: Rust plugin

- **WHEN** a caller uses `pkgs.rustPlatform.buildRustPackage` internally and wraps the output with `buildHerdrPlugin` for manifest installation
- **THEN** the Cargo build honors the sandboxed `cargoLock.lockFile` and produces the artifact under `target/release/`, which `installExtra` copies into `$dst/`

### Requirement: manifest is authoritative for `id`

The `id` argument passed to `buildHerdrPlugin` SHALL match the `id` field in the plugin's `herdr-plugin.toml`. If they diverge, the resulting `$out/share/herdr-plugins/<id>/` path will not match what `herdr plugin link` expects, and registration will fail silently.

#### Scenario: id mismatch is a build-time error

- **WHEN** `id = "wrong.id"` is passed but the manifest contains `id = "actual.id"`
- **THEN** the derivation's `installPhase` MUST fail with a clear error, not produce an incorrectly-named directory

Rationale: preventing silent divergence between `id` argument and manifest is cheap at build time and painful to debug at activation time (kevinpita's module will report the plugin as absent from the registry with no obvious cause).
