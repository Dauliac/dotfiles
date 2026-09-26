# Design — Declarative Herdr Plugins

## Context

- **Herdr plugin install today** (`herdrdev/herdr` `src/persist/plugin_registry.rs`, `src/plugin_paths.rs`): `herdr plugin install <owner>/<repo>` → git clone into `~/.config/herdr/plugins/github/<encoded-id>/` → run `[[build]]` from `herdr-plugin.toml` → append `InstalledPluginInfo` to `~/.config/herdr/plugins.json` under `.plugins.lock`. No release channel, no registry service. Plugin is invisible if `plugins.json` doesn't list it. Toolchains (go/cargo/npm/bun) must be on host `PATH`.
- **Herdr plugin `link` vs `install`**: `herdr plugin link <dir>` registers a *pre-built* plugin dir without running `[[build]]` and without needing a running server. This is the exact seam a Nix derivation can use — build in sandbox, hand `$out/share/herdr-plugins/<id>` to `link`.
- **Kevinpita's home-manager module** (`kevinpita/herdr-nix` `modules/home-manager.nix` + `lib/plugins.nix`): exposes `programs.herdr.plugins.<name>.source = <path>` where `<path>` is a directory containing `herdr-plugin.toml`. Module runs `herdr plugin link` at activation (or generates `plugins.json` itself — implementation detail we depend on but don't need to replicate). Also disables the (nonexistent-in-nixpkgs) upstream `programs/herdr.nix` module and exposes typed `programs.herdr.settings.*` mirroring all 207 upstream settings.
- **Current state of this repo**: `modules/home-manager/programs/herdr.nix` hand-writes `~/.config/herdr/config.toml` via `pkgs.formats.toml { }`, and runs `herdr integration install claude` in a `home.activation`. No plugin declaration at all today.

## Decisions

### Decision 1 — Take herdr from `kevinpita/herdr-nix`, retire the `llm-agents.nix`-sourced herdr

**What**: Add `inputs.herdr-nix.url = "github:kevinpita/herdr-nix"`. In every user config that already imports `flake.modules.homeManager.herdr`, also import `inputs.herdr-nix.homeModules.default`. `llm-agents.nix` stays for sibling agents (beads, gascity, dust, ...).

**Why not**: (a) keep hand-rolled TOML writer + hand-roll a plugin-installer via `home.activation` — rejected because kevinpita's module already solved it, typed 207 settings would be lost, and reinventing the registry+lock+link dance is a durable source of bugs. (b) use `herdrdev/herdr-nix` (official) — rejected: plain package flake, no home-manager module, no plugin story; adopting it moves us zero inches on the actual problem.

**Trade-off**: 1-star repo, plugin API landed 2026-09-07. Mitigation: the `buildHerdrPlugin` derivations are the durable value — if kevinpita's `plugins.<name>` API breaks, we swap the module for a hand-rolled `home.activation` that runs `herdr plugin link` on the same `$out/share/herdr-plugins/<id>` paths. Repo starred as lightweight signal.

### Decision 2 — Build plugins with a generic `buildHerdrPlugin` helper, one derivation per plugin

**What**: New flake-parts perSystem module at `modules/flake/herdr-plugins.nix` exposes:

```nix
pkgs.buildHerdrPlugin = { pname, version, src, id, nativeBuildInputs ? [], buildPhase, installExtra ? "" }:
  stdenv.mkDerivation {
    inherit pname version src nativeBuildInputs;
    dontConfigure = true;
    inherit buildPhase;
    installPhase = ''
      runHook preInstall
      dst=$out/share/herdr-plugins/${id}
      mkdir -p "$dst"
      cp herdr-plugin.toml "$dst/"
      ${installExtra}
      runHook postInstall
    '';
  };

pkgs.herdrPlugins.auto-title  = buildHerdrPlugin { … buildPhase = "go build -o herdr-auto-title ./cmd/herdr-auto-title"; installExtra = ''cp herdr-auto-title "$dst/"''; };
pkgs.herdrPlugins.agent-quota = buildHerdrPlugin { … buildPhase = "cargo build --release --frozen"; installExtra = ''cp target/release/herdr-agent-quota "$dst/"''; };
```

The per-plugin derivations are the *only* code that knows a plugin's build shape. Adding a plugin later = one new `pkgs.herdrPlugins.<name> = buildHerdrPlugin { ... }` block + one `plugins.<name>.source = pkgs.herdrPlugins.<name>` line. No `herdr plugin install` on the host, ever.

**Why not**: (a) auto-derive from `herdr-plugin.toml` at Nix eval time (parse the `[[build]]` argv, run it generically) — rejected because eval-time file reads of unfetched sources are fragile, per-plugin toolchains vary (Go modules need vendoring or `buildGoModule`; Rust needs `cargoLock.lockFile`), and one explicit derivation per plugin is 15 lines of clear code vs 100 lines of generic-parser complexity. (b) commit prebuilt binaries into the flake — rejected: kills reproducibility, contradicts the whole point.

### Decision 3 — Keybindings live in the herdr module's `settings`, not in the plugin derivation

**What**: Plugin `[[actions]]` are exposed by the manifest. User binds them via `programs.herdr.settings.keys.command = [ { key = "prefix+shift+q"; type = "plugin_action"; command = "herdr.agent-quota.settings"; description = "..."; } … ]` — same place all other keybindings live, next to `prefix`/`split_horizontal`/etc.

**Why**: Herdr enforces this separation itself — plugin manifest declares action ids, main `config.toml` binds them. Trying to bundle bindings with the derivation would fork that model.

### Decision 4 — Preserve `home.activation.herdrClaudeIntegration`

**What**: The existing `home.activation` that runs `herdr integration install claude` stays as-is. Kevinpita's module doesn't own integrations.

**Why**: Integrations and plugins are separate herdr subsystems. Removing the activation would silently break Claude → herdr state reporting on next deploy.

### Decision 5 — Migration is a single atomic commit per host

**What**: On each host (dauliac, juliendauliac, gary): `xi home switch .` (or `xi os switch .` / `xi system switch .` per profile) after the flake change. Before-switch: `rm -rf ~/.config/herdr/plugins ~/.config/herdr/plugins.json ~/.config/herdr/plugins.lock` to wipe any imperative pre-existing state — otherwise kevinpita's module might refuse to overwrite an existing registry.

**Why**: Making the module's activation *merge* with a pre-existing imperative registry is a source of drift bugs. Clean slate is safer, and user config/state dirs (`plugins/config/*`, `plugins/state/*`) are preserved automatically.

**Risk**: if a plugin had accumulated state under `~/.config/herdr/plugins/config/<encoded-id>/` from an imperative install, it survives — new declarative install reads it. Good.

## Non-goals

- **Not adopting `herdr-annotate`, `herdr-lazygit`, `herdr-mobile-relay`**: per prior five-plugin evaluation. `mobile-relay` is a separate future change scoped to `gary` only with an infosec review checklist.
- **Not touching `llm-agents.nix`**: it keeps packaging beads, gascity, dust, and the other 100+ agents. Only the herdr binary source shifts.
- **Not addressing the MM-skills purge**: separate change (`prune-mm-skills`) — user is a platform SRE, doesn't need `mm-skills-jvm-*` / `mm-skills-spinak-kafka-*` / etc. clogging the trigger table.
- **Not de-referencing `mm-skills-git-commit-craft` from `commit-rationale`**: separate change (`commit-rationale-standalone`) that either absorbs the title rules or drops the cross-ref.
- **Not adding a Cachix substituter** for the plugin builds yet. First measure: run `xi home switch .` cold, time it. If Rust build of `agent-quota` dominates, evaluate `kevinpita.cachix.org` + `herdr.cachix.org` as substituters in a follow-up.

## Plan drift (recorded 2026-09-11 during implementation)

The following decisions changed from the original proposal after contact with the codebase's existing conventions and upstream toolchain reality:

**PD-1 · File layout: `modules/packages/herdr-plugins/` not `modules/flake/herdr-plugins.nix`.**
The proposal placed the plugin derivations under `modules/flake/` and promised `pkgs.buildHerdrPlugin` as a public helper. Reality: this repo's convention for `pkgs.<foo>` additions is `modules/packages/<foo>[.nix|/]`, wired via the outer overlay at `modules/packages/default.nix:_ herdrPlugins = final.callPackage ./herdr-plugins { }`. Moved the derivations there. `modules/flake/herdr-plugins.nix` DOES exist but only exposes `packages.<system>.herdr-plugin-{auto-title,agent-quota}` as flat flake outputs for isolated `nix build .#herdr-plugin-*` — no plugin logic lives there.

**PD-2 · No public `pkgs.buildHerdrPlugin` helper.**
With only 2 plugins whose toolchains (Go, Rust) differ, a generic `buildHerdrPlugin` wrapper added indirection without cutting code. Kept one shared idiom — `installManifest = id: <snippet>` in `modules/packages/herdr-plugins/default.nix` — that enforces the "manifest-id must match declared id" invariant from spec `herdr/plugin-build`. Each per-plugin derivation directly uses `buildGoModule` / `rustPlatform.buildRustPackage` and splices `${installManifest "..."}` into `postInstall`. If a third plugin arrives with the same toolchain as an existing one, promote the wrapper then.

**PD-3 · `agent-quota` requires unstable's `rustPlatform` (rustc 1.95+).**
`herdr-agent-quota@1.5.4` declares `rust-version = 1.95` in its Cargo.toml; nixpkgs-25.11 ships rustc 1.91.1. Following the existing `slackapi-cli` precedent (`buildGoModule = unstablePkgs.buildGoModule` for Go 1.26+), the collector passes `rustPlatform = unstablePkgs.rustPlatform` down to `agent-quota.nix`. `auto-title` uses stable `buildGoModule` (Go 1.25 suffices).

**PD-4 · `agent-quota` skips its upstream test suite (`doCheck = false`).**
The `claude_collector_does_not_wait_for_a_refresh_lock` test in `tests/configure_round_trip.rs` is timing-based and flakes under Nix sandbox scheduling (532/532 core tests pass; 1/66 round-trip test fails). Documented in the derivation with the rationale.

**PD-5 · `$out` layout differs between the two plugins.**
`auto-title` has manifest + binary at `$out/` root (matches its `[[startup]] command = ["./herdr-auto-title"]`). `agent-quota` keeps `target/release/` subpath at `$out/target/release/herdr-agent-quota` (its manifest hardcodes `$HERDR_PLUGIN_ROOT/target/release/herdr-agent-quota` in every action/event/pane command). Verified both post-build: `find result/` matches the expected shapes.

## Open questions

- Does kevinpita's module handle *removal* correctly? — i.e. if `programs.herdr.plugins.foo` is deleted in a subsequent generation, does the next activation strip `foo` from `plugins.json` and delete the linked checkout? Needs a smoke test in the tasks below (add plugin → deploy → remove plugin → deploy → assert `plugins.json` no longer lists it, no dangling link under `plugins/github/`).
- `agent-quota` needs a `cargoLock` — its `Cargo.lock` will need to be either committed (already is per its repo) or fetched separately. Verify at pin time whether `cargoLock.lockFile = "${src}/Cargo.lock"` works or if we need `importCargoLock`.
- Do plugin manifests declare a `min_herdr_version` that our pinned herdr satisfies? Check both `auto-title/herdr-plugin.toml` and `agent-quota/herdr-plugin.toml` against the herdr version `herdr-nix` currently pins (0.9.0 per prior research). If drift → decide whether to pin herdr forward or fork the plugin.
