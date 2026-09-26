## Purpose

Documents the herdr home-manager module surface after migration from a hand-rolled `pkgs.formats.toml` writer to `inputs.herdr-nix.homeModules.default`. The user-visible config (keybindings, UI, experimental features, Claude integration) is preserved verbatim; the difference is that all 207 upstream settings are now typed options validated by `herdr config check` at build time, and the plugin subsystem gains a first-class declaration surface.

## ADDED Requirements

### Requirement: herdr module writes `~/.config/herdr/config.toml`

The herdr home-manager module SHALL generate `$XDG_CONFIG_HOME/herdr/config.toml` from typed Nix options (via `inputs.herdr-nix.homeModules.default`). The generated TOML MUST preserve the pre-change values byte-for-byte-equivalent modulo whitespace/ordering: `onboarding = false`, `keys.prefix = "ctrl+a"`, `keys.split_horizontal = "prefix+u"`, `keys.split_vertical = "prefix+i"`, `keys.detach = "prefix+d"`, `keys.rename_tab = "prefix+,"`, `keys.indexed.tabs = "alt"`, `keys.navigate_workspace_up = "k"`, `keys.navigate_workspace_down = "j"`, `ui.toast.delivery = "system"`, `ui.status_indicators = "symbols"`, `ui.show_agent_labels_on_pane_borders = true`, `ui.hide_tab_bar_when_single_tab = true`, `experimental.pane_history = true`.

#### Scenario: post-migration config is functionally equivalent

- **WHEN** `xi home switch .` runs on a host after this change lands
- **THEN** `herdr config check` reports no errors, and `diff` of the generated `~/.config/herdr/config.toml` against a snapshot of the pre-change file shows only whitespace/ordering differences (no semantic changes to key values)

### Requirement: Claude integration activation survives migration

The `home.activation.herdrClaudeIntegration` block that runs `herdr integration install claude` after `linkGeneration` SHALL survive the migration verbatim. Kevinpita's module does not own herdr integrations; only settings and plugins.

#### Scenario: Claude integration hook still fires

- **WHEN** activation runs post-migration
- **THEN** `herdr integration install claude` is invoked exactly once, its exit code is treated as non-fatal per the pre-change behavior, and `~/.claude/hooks/herdr-agent-state.sh` (or wherever herdr writes the integration script) is present afterward

### Requirement: no other module claims `programs.herdr` or `xdg.configFile."herdr/`

The herdr module SHALL be the sole owner of `programs.herdr.*` options and of `xdg.configFile."herdr/*"` entries. Any other module attempting to write herdr config MUST fail the flake evaluation.

#### Scenario: conflict detection

- **WHEN** another module (present or future) declares `xdg.configFile."herdr/config.toml"`
- **THEN** `nix flake check` reports the conflict; the herdr module is the winning writer (via `mkForce` if needed, but only as a last resort — the preferred resolution is deleting the competing module)
