## Purpose

Establishes Nix as the single source of truth for the herdr plugin registry (`~/.config/herdr/plugins.json`) on every host managed by this repo. Imperative `herdr plugin install` becomes prohibited; adding, removing, or upgrading a plugin is exclusively a flake edit followed by `xi ... switch .`.

## ADDED Requirements

### Requirement: Nix owns `~/.config/herdr/plugins.json`

On every host that imports the herdr home-manager module, the herdr plugin registry file at `$XDG_CONFIG_HOME/herdr/plugins.json` (default `~/.config/herdr/plugins.json`) SHALL be regenerated on every `xi home switch` from the set of `programs.herdr.plugins.<name>` declarations. Plugins declared in the flake MUST appear in the registry after activation; plugins not declared in the flake MUST NOT appear in the registry after activation.

#### Scenario: adding a plugin declaration

- **WHEN** a new `programs.herdr.plugins.foo.source = pkgs.herdrPlugins.foo;` line is added and `xi home switch .` runs
- **THEN** `~/.config/herdr/plugins.json` contains an entry for `foo` pointing at the store path from `pkgs.herdrPlugins.foo`

#### Scenario: removing a plugin declaration

- **WHEN** a `programs.herdr.plugins.foo.source = ...;` line is deleted and `xi home switch .` runs
- **THEN** `~/.config/herdr/plugins.json` no longer contains an entry for `foo` and the checkout directory under `~/.config/herdr/plugins/github/<encoded-foo-id>/` is either removed or clearly identified as orphaned

Note: if kevinpita's module leaves orphan checkouts on removal, that is captured as a Known Issue in the archived spec rather than blocking this change — the registry-truthiness invariant is what protects against drift.

### Requirement: `herdr plugin install` is prohibited on managed hosts

The declarative module SHALL be documented as the ONLY supported way to install a plugin on this host. The agent skill `herdr-plugins` MUST teach agents to refuse `herdr plugin install <owner>/<repo>` invocations and to instead PR a `pkgs.herdrPlugins.<name>` derivation into `modules/flake/herdr-plugins.nix` plus a `plugins.<name>.source = ...` line into the herdr module.

#### Scenario: agent is asked to install a herdr plugin

- **WHEN** a user asks Claude to install `some/herdr-plugin`
- **THEN** the agent (having loaded the `herdr-plugins` skill) refuses to run `herdr plugin install`, and instead proposes the two-file flake edit and offers to open a branch for it

### Requirement: state and per-plugin config survive activation

The activation SHALL preserve the contents of `~/.config/herdr/plugins/config/<encoded-id>/` (user-editable plugin config) and `$XDG_STATE_HOME/herdr/plugins/<encoded-id>/` (default `~/.local/state/herdr/plugins/<encoded-id>/`, runtime state) across generations. Only the checkout dir under `~/.config/herdr/plugins/github/<encoded-id>/` and the registry file `~/.config/herdr/plugins.json` are Nix-owned.

#### Scenario: user-tuned plugin config survives redeploy

- **WHEN** a user has edited `~/.config/herdr/plugins/config/herdr.auto-title/config.env` to raise `HERDR_AUTO_TITLE_POLL_MS` from 500 to 1000, and then `xi home switch .` runs
- **THEN** the edited value is preserved on disk after activation

### Requirement: migration from pre-existing imperative state

The first activation on a host that previously had imperative plugin installs SHALL either safely overwrite the pre-existing `plugins.json` and `plugins/github/` contents, or the migration procedure (in the archived spec) MUST document a manual `rm -rf` step to run before the first switch.

#### Scenario: host with pre-existing imperative plugins

- **WHEN** a host has `~/.config/herdr/plugins.json` from previous imperative `herdr plugin install` invocations and the migration `rm -rf ~/.config/herdr/plugins ~/.config/herdr/plugins.json ~/.config/herdr/plugins.lock` is performed before `xi home switch .`
- **THEN** activation succeeds and the resulting registry contains exactly the flake-declared plugins
