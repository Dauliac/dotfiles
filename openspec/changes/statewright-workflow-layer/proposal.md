## Why

Skill pipelines like `jira-ticket` are implicit state machines: they poll, lock,
transition, and inject events across explore → fix → answer stages, but the FSM
lives hardcoded in prose inside each skill's SKILL.md. That makes transitions
unverifiable, tool allowlists per-state unenforceable, and cross-session resume
manual. Introduce **statewright** (Rust MCP server, JSON workflow files) as a
declarative layer so pipelines become inspectable, guarded, and replayable —
starting with support-ticket as the first target so we prove the model on a
well-understood pipeline before generalizing.

## What Changes

- Add statewright's three binaries to the Nix flake: `statewright-gateway`
  (fetched from the upstream `gateway-v*` release zip, Linux x86_64) and
  `sw-agent` + `statewright` (TUI) built from source via
  `rustPlatform.buildRustPackage` against the workspace. `llm-agents.nix`
  does not currently ship statewright.
- Add a new home-manager AI capability module
  `modules/home-manager/ai/capability/statewright.nix` that installs the
  three binaries plus a `statewright approve <instance-id> <event>` operator
  wrapper (statewright's own CLI has no first-class `approve` command),
  wires the gateway as an MCP server into Claude Code settings, and ships
  workflow JSON files.
- Add a first workflow `workflows/support-ticket.json` modelling the current
  `jira-ticket` skill FSM (states, guards, per-state tool allowlists, human
  approval gates).
- Add a slash command `/sw:ticket <ticket-id>` that boots a workflow instance
  and hands control to statewright.
- Extend the `jira-ticket` skill with a `--via-statewright` A/B toggle so the
  hardcoded path stays as a rollback until parity is proven, then flip the
  default. **BREAKING** once the default flips — the skill will refuse to run
  outside a workflow instance unless `--legacy` is passed.
- Persist workflow event streams to `~/.cache/claude/statewright/<instance-id>/`
  for replay + observability.

## Capabilities

### New Capabilities

- `agent-workflows`: declarative FSM layer for skill pipelines — how workflows
  are defined, packaged, invoked, transitioned, guarded, persisted, observed,
  and replayed. Covers the statewright binary as MCP server, JSON workflow
  schema conventions, per-state tool allowlists, human-approval gate semantics,
  event-stream persistence, and cross-session resume.
- `agent-workflows/support-ticket`: the concrete support-ticket workflow — its
  state graph, transition guards, per-state tool allowlists, and the migration
  path from the hardcoded `jira-ticket` skill (A/B toggle, cutover criteria,
  legacy fallback).

### Modified Capabilities

None yet — `jira-ticket` currently lives as a skill file, not an OpenSpec spec.
Its behavior migration is captured under the new
`agent-workflows/support-ticket` capability rather than as a delta.

## Impact

- **Nix**: new derivation + capability module; touches `flake.nix` inputs only
  if `llm-agents.nix` does not already package statewright.
- **Claude Code settings**: new `.claude/settings.d/` MCP entry (managed via
  Nix, not hand-edited).
- **Skills**: `jira-ticket` gains an A/B branch; other skills untouched in this
  change (workflow-per-skill migration is future scope).
- **Runtime state**: `~/.cache/claude/statewright/` becomes a new persistence
  root; safe to `rm -rf` for a clean slate.
- **Dependencies**: adds statewright (Rust) as a runtime dep for AI capability
  hosts; no impact on non-AI hosts.
- **Beads / gascity**: no touch — statewright sits inside a single bead's
  execution, above the queue/dispatch layer that gascity owns.
