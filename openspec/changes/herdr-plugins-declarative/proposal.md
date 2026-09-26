## Why

Herdr plugins (e.g. `kryptamine/herdr-auto-title`, `levi-qiao/herdr-agent-quota`) today install via `herdr plugin install <owner>/<repo>` — an imperative git-clone-then-build-then-register flow that mutates `~/.config/herdr/plugins/`, `~/.config/herdr/plugins.json`, and writes plugin config outside the Nix store. That's a direct hit against this repo's dendritic, flake-driven reproducibility model: a `xi home switch` on a fresh host does not resurrect the plugins, plugin versions drift silently, and per-plugin config keys (`config.env`, `panel.conf`, etc.) live outside git. The hand-rolled `modules/home-manager/programs/herdr.nix` writes `~/.config/herdr/config.toml` via `pkgs.formats.toml { }` but stops at the plugin boundary, and the existing `llm-agents.nix` input packages the herdr binary but not its plugin surface. Result: agents running Claude Code across `spongebob`/`gary`/`juliendauliac`/`dauliac` cannot rely on the same herdr behaviour, and there's no single-source-of-truth for which plugins ship with the workspace.

Upstream is `kevinpita/herdr-nix` (adopted 2026-09-07): first-class `programs.herdr.plugins.<name>.source = <path>` option that expects a pre-built plugin dir with `herdr-plugin.toml` and links it via `herdr plugin link` (registers without running build commands). This change adopts that module, layers a `buildHerdrPlugin` helper for building plugins from their `[[build]]` sections in the Nix sandbox, and declares `auto-title` and `agent-quota` as the first two consumers — chosen from a prior five-plugin evaluation (see conversation trail; `auto-title` solves the "which pane is which agent" pain across beads/gascity/openspec/formulas, `agent-quota` gives live cx-window headroom per pane on Opus 4.7 1M-context).

## What Changes

- Add `inputs.herdr-nix.url = "github:kevinpita/herdr-nix"` to `flake.nix`; wire its `homeModules.default` into every user config that already imports the current `flake.modules.homeManager.herdr` (dauliac, juliendauliac, gary).
- Introduce a new flake-parts perSystem module at `modules/flake/herdr-plugins.nix` that exposes `pkgs.buildHerdrPlugin` (generic derivation helper) and `pkgs.herdrPlugins.{auto-title,agent-quota}` (per-plugin instantiations). The helper runs each plugin's `[[build]]` from `herdr-plugin.toml` in the sandbox and installs to `$out/share/herdr-plugins/<id>/`.
- Rewrite `modules/home-manager/programs/herdr.nix` to consume `inputs.herdr-nix.homeModules.default` via `imports`, migrate the existing TOML config (keys, ui, experimental.pane_history) into `programs.herdr.settings.*`, and declare `programs.herdr.plugins.{auto-title,agent-quota}.source` pointing at the new derivations. Remove the hand-rolled `xdg.configFile."herdr/config.toml"` line — kevinpita's module owns it.
- Preserve the existing `home.activation.herdrClaudeIntegration` hook that runs `herdr integration install claude` (kevinpita's module doesn't touch integrations).
- Add plugin keybindings (`prefix+shift+q` for agent-quota's settings pane; `auto-title` needs none — polls in the background) as `[[keys.command]]` entries with `type = "plugin_action"` inside the same herdr settings.
- Ship a Claude skill at `modules/home-manager/ai/capability/skills/engineering/herdr-plugins/SKILL.md` teaching agents (a) how to add a new plugin (`buildHerdrPlugin` recipe + `plugins.<name>.source =` line), (b) that `herdr plugin install` must NEVER run on this host (the registry is Nix-owned), and (c) the "if you want a plugin from GitHub, PR it into `modules/flake/herdr-plugins.nix`" contract.

## Capabilities

### New Capabilities

- `herdr/plugin-build`: the `buildHerdrPlugin` derivation helper — takes `{ pname, version, src, id, nativeBuildInputs, buildPhase, installExtra }`, runs the plugin's declared build in the Nix sandbox, and installs a self-contained plugin dir (manifest + built artifacts) to `$out/share/herdr-plugins/<id>/`. Never touches network at eval time; hash-pinned via `fetchFromGitHub`.
- `herdr/plugin-registry`: the `programs.herdr.plugins.<name>` declaration surface — Nix owns the herdr plugin registry (`~/.config/herdr/plugins.json`), imperative `herdr plugin install` is forbidden on the host. Registry is regenerated on every `xi home switch`; drift is impossible because plugins not in the flake are absent from `plugins.json`.
- `herdr/plugin-catalog`: the initial two-plugin catalog (`auto-title`, `agent-quota`) — one Go build, one Rust build, both exercised on every deploy so the plumbing is proven before adding more.

### Modified Capabilities

- `herdr/config`: existing `modules/home-manager/programs/herdr.nix` (informal, no prior spec) transitions from a hand-rolled `pkgs.formats.toml`-based TOML writer to `inputs.herdr-nix.homeModules.default`'s typed `programs.herdr.settings.*` option tree. The `home.activation.herdrClaudeIntegration` block survives verbatim (kevinpita's module doesn't own integrations).

## Impact

- **Flake inputs**: `+1` (`herdr-nix`). `llm-agents.nix` is retained for the sibling agent packages (beads, gascity, dust) but no longer sourced for the herdr binary — herdr comes from `herdr-nix` now.
- **Host coverage**: dauliac (NixOS), juliendauliac (system-manager on ML-PF603JJ8), gary (NixOS home server). spongebob shares dauliac's HM module transitively.
- **Toolchain footprint**: first `nix build` pulls Go + Rust closures for the two plugin builds. If eval becomes slow, evaluate `herdr.cachix.org` (from `herdrdev/herdr-nix`) or `kevinpita.cachix.org` as a substituter.
- **Rollback**: revert the module + drop the input; `rm -rf ~/.config/herdr/plugins ~/.config/herdr/plugins.json` on each host to nuke the Nix-linked registry, then either reinstall imperatively or accept no plugins. Config + state dirs are user-owned and preserved.
- **Risk**: `kevinpita/herdr-nix` is 1-star, plugin API landed 2026-09-07 — early adopter surface. Mitigation: the two `buildHerdrPlugin` derivations are the durable value; if the module's `plugins.<name>` API breaks, we can fall back to a hand-rolled `home.activation` that runs `herdr plugin link "$out/share/herdr-plugins/<id>"` against the same derivations. Repo starred (2026-09-10) as a lightweight signal.
- **Out of scope**: `herdr-annotate` (skipped per prior eval), `herdr-lazygit` (redundant with existing `hunk`/`commit-rationale`/`glab` stack), `herdr-mobile-relay` (SRE/infosec review pending for gary-only rollout — its own change later). MM-skills purge is orthogonal (separate change).
