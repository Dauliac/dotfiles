## Purpose

Defines the two nix option namespaces — `dotfiles.profiles.*` and `dotfiles.scopes.*` — that give the `dot` binary its declarative view of the repo. Every piece of configuration `dot` itself needs is expressed here in nix (via `nlib` option builders) and consumed by the binary through `nix eval --json`; no rust-side YAML/TOML config file is allowed.

## ADDED Requirements

### Requirement: dotfiles.profiles maps hostname to xi dispatch

The flake SHALL expose an evaluatable option `dotfiles.profiles` of type `attrsOf (submodule …)`, keyed by hostname (matching `hostnamectl hostname`). Each submodule SHALL contain the following fields, defined with `nlib` option builders: `kind` (enum `"home" | "os" | "system"`), `flakeAttr` (string — the attribute path passed to xi, e.g. `.#homeConfigurations.juliendauliac`), `description` (string, optional), `hostnameAliases` (list of strings, optional — additional hostnames that map to the same profile), and `comin` (sub-submodule, optional — see the next requirement).

#### Scenario: current hosts are declared

- **WHEN** the option is evaluated on any host of this repo
- **THEN** `dotfiles.profiles` contains entries for `spongebob`, `gary`, `dauliac`, `juliendauliac`, and the system-manager host `ML-PF603JJ8` (with an alias for the retired predecessor `ML-PF59GCGW`)

#### Scenario: option surface is nlib-declared

- **WHEN** the module defining `dotfiles.profiles` is inspected
- **THEN** the `type` is built with `nlib` combinators (not raw `lib.types`) and passes `nix flake check`

### Requirement: profile.comin declares GitOps push-to-deploy status

Each `dotfiles.profiles.<host>` submodule SHALL accept an optional `comin` sub-submodule of shape `{ enabled = bool; remote = string; branch = string; }`, defined with `nlib` combinators. `enabled` defaults to `false`. When `enabled == true`, `remote` and `branch` MUST be non-empty and identify the git remote and branch that the comin daemon (github.com/nlewo/comin) on that host watches for auto-apply. When `enabled == false` (or the whole `comin` field is absent), the host is in local-apply mode: `dot deploy` performs the `xi ... switch .` itself. The nix module MUST NOT default any host to `comin.enabled = true` — enabling GitOps is always an explicit opt-in per host.

#### Scenario: host without comin

- **WHEN** a profile omits the `comin` field entirely
- **THEN** evaluating `dotfiles.profiles.<host>.comin.enabled` returns `false` and evaluating `dotfiles.profiles.<host>.comin.remote` and `.branch` returns the empty string

#### Scenario: host with comin enabled

- **WHEN** a profile sets `comin = { enabled = true; remote = "origin"; branch = "main"; }`
- **THEN** evaluating the sub-submodule returns exactly those three values and `nix flake check` passes

#### Scenario: comin enabled without remote/branch is a type error

- **WHEN** a profile sets `comin.enabled = true` but leaves `remote` or `branch` empty
- **THEN** `nix flake check` fails with a message identifying the offending host and field

### Requirement: dotfiles.scopes groups modules into coherent bundles

The flake SHALL expose an evaluatable option `dotfiles.scopes` of type `attrsOf (submodule …)`, keyed by scope name (kebab-case). Each submodule SHALL contain: `description` (string, non-empty), `paths` (list of relative paths, relative to the flake root, each pointing at a directory or `.nix` file), `hosts` (list of hostnames — empty means "all hosts"), and `narrowsBuild` (bool — whether `dot build --scope <name>` can restrict `nix build` to a subset of outputs, versus falling back to a full build).

#### Scenario: minimum required scopes exist

- **WHEN** the option is evaluated
- **THEN** `dotfiles.scopes` includes at least `desktop`, `ai`, `terminal`, `security`, and each has non-empty `paths` and a non-empty `description`

#### Scenario: patch by scope maps to concrete files

- **WHEN** `dot patch --scope ai --json` runs
- **THEN** `data.candidate_paths` equals the evaluated `dotfiles.scopes.ai.paths`, resolved to absolute paths under the flake root

### Requirement: nix eval is the only source of dot's config

The `dot` binary SHALL read `dotfiles.profiles` and `dotfiles.scopes` via `nix eval --json .#dotfiles.profiles` (and similarly for scopes) and MUST NOT read any YAML/TOML/JSON config file colocated with the binary or under `$XDG_CONFIG_HOME/dot/`. The only rust-side inputs allowed are environment variables enumerated in the `core` capability spec.

#### Scenario: no colocated config file is loaded

- **WHEN** `dot detect` runs while a file exists at `$XDG_CONFIG_HOME/dot/config.toml`
- **THEN** the file is ignored, and (under `--json`) `data.config_source == "nix-eval"`

### Requirement: scope and profile changes require no rebuild of dot

Adding a new host or scope SHALL take effect the next time `dot` invokes `nix eval` — the `dot` binary MUST NOT be recompiled to see the change, and no restart of a long-running daemon is required. Evaluation results MAY be cached in memory for the lifetime of a single `dot` invocation but MUST NOT be persisted across invocations.

#### Scenario: adding a new scope

- **WHEN** the user adds `dotfiles.scopes.observability = { description = "…"; paths = [ … ]; hosts = []; narrowsBuild = false; };` and stages the file
- **THEN** the very next `dot status --json` on the same shell shows the new scope in `data.scopes` without any prior rebuild step

### Requirement: git-staged requirement for evaluation

Because this flake follows the dendritic pattern (files must be git-staged to be visible), `dot` MUST detect unstaged `.nix` files under any registered scope path and surface them in `dot status`'s output under `data.warnings[]` with code `unstaged-nix-file`. `dot` MUST NOT auto-stage them.

#### Scenario: unstaged module

- **WHEN** the user has modified `modules/home-manager/programs/foo.nix` and not staged it, and this path is inside `dotfiles.scopes.terminal.paths`
- **THEN** `dot status --json` reports `data.warnings[] == [{code: "unstaged-nix-file", path: "modules/home-manager/programs/foo.nix", scope: "terminal"}]`
