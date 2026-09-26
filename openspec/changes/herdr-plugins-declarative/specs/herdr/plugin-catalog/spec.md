## Purpose

Defines the initial declarative herdr plugin catalog — the concrete set of plugins that ship with this dotfiles repo. Adding a plugin to the catalog is the durable, reviewable act; removing one from the catalog is the durable, reviewable act. The catalog is what other agents and hosts can be told "this is what herdr does on our workstations."

## ADDED Requirements

### Requirement: `herdr-auto-title` is a catalog member

The flake SHALL expose `pkgs.herdrPlugins.auto-title` as a `buildHerdrPlugin`-built derivation whose `src` is `pkgs.fetchFromGitHub { owner = "kryptamine"; repo = "herdr-auto-title"; rev = <pinned commit sha>; hash = <sri>; }` and whose `id` matches the `id` field of the upstream manifest at that revision. The herdr home-manager module SHALL declare `programs.herdr.plugins.auto-title.source = pkgs.herdrPlugins.auto-title;`.

#### Scenario: fresh install on juliendauliac

- **WHEN** `xi home switch .` runs on `juliendauliac` after this change lands
- **THEN** herdr tab titles auto-update following the `<position> · <context> › <activity>` pattern within `HERDR_AUTO_TITLE_POLL_MS` ms of a context change (default 500ms)

### Requirement: `herdr-agent-quota` is a catalog member

The flake SHALL expose `pkgs.herdrPlugins.agent-quota` as a derivation whose `src` is `pkgs.fetchFromGitHub { owner = "levi-qiao"; repo = "herdr-agent-quota"; rev = <pinned commit sha>; hash = <sri>; }` with a Cargo build (via `rustPlatform.buildRustPackage` or equivalent) and `cargoLock.lockFile` pointing at the upstream `Cargo.lock`. The herdr home-manager module SHALL declare `programs.herdr.plugins.agent-quota.source = pkgs.herdrPlugins.agent-quota;` and SHALL bind the plugin's settings-pane action to `prefix+shift+q` via `programs.herdr.settings.keys.command`.

#### Scenario: agent-quota gauges appear after first turn

- **WHEN** a Claude Code session runs in a herdr pane on a host with the plugin installed
- **THEN** after the user sends the first turn, the agent sidebar shows per-pane gauges for `cx` (context window headroom), `5h` (subscription burn), and cache TTL

### Requirement: catalog changes are the only way to adopt a plugin

Adding a new plugin to the catalog SHALL require: (a) a new `pkgs.herdrPlugins.<name>` entry in `modules/flake/herdr-plugins.nix`, (b) a new `plugins.<name>.source = ...` line in the herdr home-manager module, and optionally (c) new `settings.keys.command` entries for any keybound plugin actions. No other path (imperative `herdr plugin install`, curl-based installers, ad-hoc `home.file` drops) is supported.

#### Scenario: adding a third plugin

- **WHEN** a maintainer wants to add `example/herdr-example` to the catalog
- **THEN** they open a branch adding one derivation to `modules/flake/herdr-plugins.nix` and one option line to the herdr module, and this two-file diff (plus any keybindings) is sufficient for a `xi home switch .` on every host to install it

### Requirement: plugin pins are exact commit shas, not branches

Every `fetchFromGitHub` in the catalog SHALL pin `rev` to a full 40-character commit sha (not a tag, not a branch name). Version bumps are explicit flake edits with updated `hash`.

#### Scenario: renovate-style bump

- **WHEN** a maintainer wants to bump `herdr-auto-title` from sha `abc…` to sha `def…`
- **THEN** they update both `rev` and `hash` in the same commit, and the change is reviewable as a two-line diff plus any consequent manifest-version bump in the module
