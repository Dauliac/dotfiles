# Tasks — Declarative Herdr Plugins

Sequenced so each block is a shippable slice. Deploy after each of §2, §3, §4 to catch regressions early. **Do not run `/opsx:apply`** — this list is what `beads-plan plan openspec/changes/herdr-plugins-declarative` decomposes into a bead DAG.

## §1 · Pin & smoke-test upstream

- [ ] 1.1 — Read `herdr-plugin.toml` for `kryptamine/herdr-auto-title` at its current head; record `id`, `version`, `min_herdr_version`, and the exact `[[build]]` argv. Pin a commit sha.
- [ ] 1.2 — Same for `levi-qiao/herdr-agent-quota`: `id`, `version`, `min_herdr_version`, `[[build]]` argv, and confirm `Cargo.lock` is committed.
- [ ] 1.3 — Check `kevinpita/herdr-nix`'s currently-pinned herdr version in `package.nix`; confirm it satisfies both plugins' `min_herdr_version`. If not, decide: pin herdr forward via kevinpita's flake, or block on upstream bump.

## §2 · Wire kevinpita/herdr-nix into the flake (no plugins yet)

- [ ] 2.1 — Add `inputs.herdr-nix.url = "github:kevinpita/herdr-nix"` to `flake.nix`. Pin to a commit sha (not a branch). Update `flake.lock`.
- [ ] 2.2 — Rewrite `modules/home-manager/programs/herdr.nix`: `imports = [ inputs.herdr-nix.homeModules.default ]`, migrate the existing `config = { onboarding = false; keys = {...}; ui = {...}; experimental.pane_history = true; }` block into `programs.herdr.settings.*`. Drop the `pkgs.formats.toml` writer and the `xdg.configFile."herdr/config.toml"` line. **Preserve** the `home.activation.herdrClaudeIntegration` block verbatim.
- [ ] 2.3 — Verify no other module claims `programs.herdr` — grep the tree for `programs.herdr` and `xdg.configFile."herdr/`.
- [ ] 2.4 — Deploy: `xi home switch .` on `juliendauliac` (fastest iteration). Verify `~/.config/herdr/config.toml` is generated, contents match previous file byte-for-byte modulo formatting.
- [ ] 2.5 — Confirm herdr still starts (`systemctl --user status herdr`), Claude integration still fires (`ls ~/.config/herdr/integrations/claude*`).

## §3 · `buildHerdrPlugin` helper + `auto-title` (Go, simplest)

- [ ] 3.1 — Create `modules/flake/herdr-plugins.nix` as a flake-parts perSystem module. Expose `pkgs.buildHerdrPlugin` per §Decision 2 in `design.md`. Include the `dontConfigure = true` and manifest-copy in the shared `installPhase`.
- [ ] 3.2 — Define `pkgs.herdrPlugins.auto-title` in the same file using `pkgs.buildGoModule` (or `buildHerdrPlugin` wrapping `go build` — pick whichever leaves fewer hash-pinning footguns; `buildGoModule` is the usual answer for Go). Point `src` at `pkgs.fetchFromGitHub { owner = "kryptamine"; repo = "herdr-auto-title"; rev = <pinned sha>; hash = <sri>; }`.
- [ ] 3.3 — `nix build .#herdrPlugins.auto-title` in isolation. Verify `$out/share/herdr-plugins/<id>/` contains `herdr-plugin.toml` + the built binary.
- [ ] 3.4 — Extend `modules/home-manager/programs/herdr.nix`: `programs.herdr.plugins.auto-title.source = pkgs.herdrPlugins.auto-title;`.
- [ ] 3.5 — Deploy on `juliendauliac`: `xi home switch .`. Verify `~/.config/herdr/plugins.json` contains the entry, `~/.config/herdr/plugins/github/<encoded>/` exists and points at the store path.
- [ ] 3.6 — Restart herdr (`systemctl --user restart herdr`). Open several splits + a claude pane in one. Verify tab titles auto-update to `<pos> · <ctx> › <activity>` pattern.
- [ ] 3.7 — Commit `auto-title` slice.

## §4 · `agent-quota` (Rust, cargoLock)

- [ ] 4.1 — Define `pkgs.herdrPlugins.agent-quota` in `modules/flake/herdr-plugins.nix` using `pkgs.rustPlatform.buildRustPackage` (or `buildHerdrPlugin` wrapping `cargo build --release --frozen`). Point `cargoLock.lockFile = "${src}/Cargo.lock"`.
- [ ] 4.2 — `nix build .#herdrPlugins.agent-quota` in isolation. If the vendored deps hash fails, capture the correct SRI hash and update. Verify `$out/share/herdr-plugins/<id>/` contains manifest + binary.
- [ ] 4.3 — Wire `programs.herdr.plugins.agent-quota.source = pkgs.herdrPlugins.agent-quota;` and add the settings-pane keybinding to `programs.herdr.settings.keys.command = [ … { key = "prefix+shift+q"; type = "plugin_action"; command = "..."; description = "agent-quota settings"; } ];` (exact command id read from `agent-quota`'s manifest in §1.2).
- [ ] 4.4 — Deploy on `juliendauliac`. In the herdr sidebar, verify agent-quota gauges appear per pane (may need to send a claude turn first — quota reading is populated after first message per prior research).
- [ ] 4.5 — Commit `agent-quota` slice.

## §5 · Removal smoke test (per §Open questions in design.md)

- [ ] 5.1 — In a scratch commit, temporarily comment out `plugins.auto-title.source = …`. Deploy. Verify `plugins.json` no longer lists it and `plugins/github/<encoded-id>/` is removed (or, if the module leaves it in place, note the exact residue and either accept or file an upstream issue).
- [ ] 5.2 — Uncomment, redeploy, verify re-installation is clean.

## §6 · Roll out to other hosts

- [ ] 6.1 — Deploy on `dauliac` (NixOS): `sudo xi os switch .`. Verify same outcomes as §3.6/§4.4.
- [ ] 6.2 — Deploy on `gary` (NixOS home server): `xi os switch .` remotely. Verify.
- [ ] 6.3 — Deploy on `spongebob` (NixOS): `xi os switch .`. Verify.

## §7 · Docs + agent skill

- [ ] 7.1 — Write `modules/home-manager/ai/capability/skills/engineering/herdr-plugins/SKILL.md`. Contents: (a) how to add a plugin (fetchFromGitHub → buildHerdrPlugin → plugins.<name>.source), (b) hard prohibition on `herdr plugin install`, (c) how to bind plugin actions in settings, (d) the `min_herdr_version` check.
- [ ] 7.2 — Register the skill in `modules/home-manager/ai/capability/skills.nix`'s `engineering` list.
- [ ] 7.3 — Update `CLAUDE.md` if the "Coding-agent pipeline" section needs a note about the herdr-plugins skill (probably not — the skill's own trigger table handles discovery).

## §8 · Archive

- [ ] 8.1 — `openspec validate herdr-plugins-declarative` passes.
- [ ] 8.2 — `openspec archive herdr-plugins-declarative` merges the three capability deltas into `openspec/specs/`.
