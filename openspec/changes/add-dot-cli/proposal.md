## Why

Deploying this dotfiles repo today requires a human to know which of three `xi` subcommands applies to the current host (`xi home switch`, `xi os switch`, `xi system switch`), where the flake is checked out, and which imperative fix-up scripts (`redeploy.sh`) to reach for when a bad deploy strips nix from `PATH`. AI coding agents driving the repo from arbitrary working directories have no stable, machine-readable surface to plan against, so every session re-derives the same host/profile logic from `hostnamectl` and shell history. A single Rust CLI — `dot` — collapses that tacit knowledge into one declarative, agent-friendly interface and makes the "zero to working laptop" path a one-liner on both NixOS and non-NixOS hosts.

## What Changes

- Add a Rust workspace at `pkgs/dot/` that builds a single `dot` binary, packaged as a nix derivation and installed via home-manager.
- Ship `dot` subcommands: `bootstrap`, `detect`, `patch`, `build`, `deploy`, `commit`, `push`, `status` — each with `--json` output and documented, stable exit codes.
- Introduce a nix option namespace `dotfiles.scopes.<name>` (defined with `nlib`) that groups coherent module bundles (`desktop`, `ai`, `terminal`, `security`, ...) with `paths`, `hosts`, and `description` fields. `dot` reads this via `nix eval --json`; there is **no** parallel rust-side YAML/TOML config.
- Introduce a nix option `dotfiles.profiles.<hostname>` mapping detected hostname → `{ kind = "home" | "os" | "system"; flakeAttr = "..."; }`, again via `nlib`. `dot deploy` dispatches to the matching `xi ... switch .` invocation.
- Publish a `curl … | sh` bootstrap script (checked into the repo, served from a stable URL the user configures) that: detects OS, installs Lix/Nix if missing (Determinate installer on non-NixOS, no-op on NixOS), clones the dotfiles flake to `$HOME/ghq/github.com/Dauliac/dotfiles`, and runs `xi home switch .` for the initial converge — resulting in `dot` on `PATH`.
- Ship a Claude skill at `modules/home-manager/ai/capability/skills/dot/SKILL.md` that teaches agents when to invoke `dot` vs. when to fall back to raw `xi` and when to reach for `redeploy.sh`.
- Preserve `redeploy.sh` as the break-glass path; `dot` explicitly documents it as the escape hatch and never removes/overwrites it.

## Capabilities

### New Capabilities

- `dot-cli/core`: the `dot` binary itself — CLI framing, `--json` output contract, deterministic exit codes, and the host/profile detection that every other subcommand consumes.
- `dot-cli/bootstrap`: the `curl … | sh` zero-install path that provisions Lix/Nix and the flake on a bare NixOS or non-NixOS host, ending with `dot` on `PATH`.
- `dot-cli/scopes`: the nix-declared `dotfiles.scopes.*` and `dotfiles.profiles.*` option namespaces (defined with `nlib`) that give `dot` its dendritic view of the repo. Declarative-or-nothing: no rust-side config file is allowed.
- `dot-cli/deploy`: the `patch`, `build`, `deploy`, `commit`, `push` subcommands that wrap `xi` and `git`, dispatched by the detected profile. Never re-implements what `xi` already does.
- `dot-cli/agent-integration`: the `SKILL.md` published under `modules/home-manager/ai/capability/skills/dot/` and the stable JSON/exit-code contract that lets Claude Code drive `dot` from any working directory without re-deriving host logic each session.

### Modified Capabilities

<!-- None. The repo has no pre-existing OpenSpec specs (openspec/specs/ is empty at proposal time), so all capabilities are net-new. -->

## Impact

- **New code**: `pkgs/dot/` Rust workspace (~1 crate), `pkgs/dot/default.nix` derivation, `modules/generic/dot.nix` option definitions using `nlib`, `modules/home-manager/programs/dot.nix` install wiring, `modules/home-manager/ai/capability/skills/dot/SKILL.md`.
- **New file at repo root**: `install.sh` (the bootstrap target of `curl … | sh`).
- **Flake surface**: exposes `packages.<system>.dot` and (optionally) `apps.<system>.dot` so `nix run github:Dauliac/dotfiles#dot -- ...` works pre-bootstrap.
- **Dependencies**: adds `nixpkgs` `rustPlatform` build path; no new flake inputs required (crates come from crates.io via `crane` or `rustPlatform.buildRustPackage` — decided in `design.md`).
- **Existing scripts**: `redeploy.sh` stays as-is; `dot doctor` (subcommand under `core`) references it in its output when it detects a broken PATH.
- **Existing xi workflow**: unchanged. `dot deploy` is a strict superset — running `xi home switch .` by hand continues to work identically.
- **User memory / MEMORY.md**: the "Deploys directly with `xi`" note stays true; `dot` is an optional agent-facing wrapper, not a mandatory layer.
- **Blast radius**: additive. No existing module is deleted or renamed by this change.
