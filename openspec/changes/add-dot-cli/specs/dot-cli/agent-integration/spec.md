## Purpose

Defines the surface Claude Code (and other coding agents) see when driving this repo: the shipped `SKILL.md`, the guarantees on which `dot` can be relied on from any working directory, and the guardrails that keep agents from bypassing the flake in dangerous ways. The `core` capability defines the JSON/exit-code contract itself; this capability is about *how agents discover and adopt it*.

## ADDED Requirements

### Requirement: dot skill is shipped inside the flake

A skill file SHALL live at `modules/home-manager/ai/capability/skills/dot/SKILL.md` and be installed to `~/.claude/skills/dot/SKILL.md` by the existing `capability/skills.nix` mechanism. The skill's front-matter description SHALL trigger on the phrases `dot patch`, `dot deploy`, `dot build`, `dot commit`, `dot push`, `dot bootstrap`, and `deploy dotfiles`.

#### Scenario: skill is installed on switch

- **WHEN** the user runs `xi home switch .` on any host in `dotfiles.profiles`
- **THEN** `~/.claude/skills/dot/SKILL.md` exists and its content matches the source file

#### Scenario: skill triggers on phrase

- **WHEN** Claude Code sees a prompt containing `deploy dotfiles`
- **THEN** the skill activation sequence surfaces the `dot` skill as a YES candidate

### Requirement: skill teaches dot-vs-xi-vs-redeploy fallback

The `SKILL.md` SHALL document, as an explicit decision list, when the agent uses `dot`, when it falls back to raw `xi`, and when it reaches for `redeploy.sh`. Concretely:

- Prefer `dot` for anything the agent can express through its subcommands.
- Use raw `xi …` when the required subcommand is not yet in `dot` (e.g., experimenting with a flag that has no `dot` equivalent).
- Use `./redeploy.sh` only when `dot doctor` reports `nix-on-path: false` — i.e., the escape hatch after a bad deploy stripped nix from `PATH`.

#### Scenario: agent picks the right tool

- **WHEN** Claude Code needs to converge the current host and `dot doctor` returns `ok`
- **THEN** the skill directs the agent to run `dot deploy`, not `xi … switch .` or `./redeploy.sh`

#### Scenario: agent hits a broken PATH

- **WHEN** `dot doctor --json` reports `nix-on-path: false`
- **THEN** the skill directs the agent to run `./redeploy.sh` from the flake root and only re-attempt `dot` after `dot doctor` clears

### Requirement: schema_version is honored by the skill

The `SKILL.md` SHALL declare which `schema_version` of the `dot --json` contract it was written against and MUST instruct the agent to abort with a warning if `dot --version --json` reports a lower `schema_version` than the skill's minimum. This prevents an agent from reading `data.*` fields that do not exist in an older binary.

#### Scenario: skill and binary agree

- **WHEN** the skill declares `min_schema_version: 1` and `dot --version --json` reports `schema_version: 1`
- **THEN** the agent proceeds

#### Scenario: skill newer than binary

- **WHEN** the skill declares `min_schema_version: 2` and `dot --version --json` reports `schema_version: 1`
- **THEN** the agent prints a warning, does not invoke `dot`, and tells the user to update the flake

### Requirement: nix run entry point works without prior install

The flake SHALL expose `packages.<system>.dot` and `apps.<system>.dot` so that `nix run github:Dauliac/dotfiles#dot -- <subcommand>` succeeds on any machine with only nix installed — no prior clone, no prior `xi`. This is what lets an agent invoked on a stranger's machine still act deterministically without touching the user's `$HOME`.

#### Scenario: pre-install nix run

- **WHEN** an agent runs `nix run github:Dauliac/dotfiles#dot -- detect --json` on a machine with nix but no local clone
- **THEN** it exits `0` and prints a JSON document with `data.hostname`, `data.os_family`, `data.nix_available`, and `data.profile` (possibly `null` if the host is unknown)

### Requirement: agent guardrails on destructive commands

The `SKILL.md` SHALL instruct the agent to never invoke `dot push --force`, `dot push --allow-dirty`, `dot commit --amend` (if later added), or any subcommand with `--yes-i-know` without explicit user confirmation in the same turn. `dot` itself enforces the flag-level guard (see `deploy` spec); the skill enforces the intent-level guard.

#### Scenario: agent tempted to force-push

- **WHEN** the agent's plan would run `dot push --force`
- **THEN** the skill directs it to pause, restate the intent to the user, and only proceed after explicit approval
