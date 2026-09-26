## 1. Recon

- [ ] 1.1 Fetch statewright README, example workflows, and MCP tool schema; write a cheatsheet to `docs/statewright/cheatsheet.md` and verify the file lists workflow JSON top-level keys, MCP tool signatures, and the CLI approval command
- [ ] 1.2 Reverse-engineer the current `jira-ticket` skill FSM (states, transitions, guards, poll/lock points) into `docs/statewright/jira-ticket-fsm.md` and verify the doc names every state referenced by the support-ticket spec

## 2. Nix packaging

- [ ] 2.1 Package `statewright-gateway` from the upstream `gateway-v*` release zip (Linux x86_64) as a `fetchurl` + `install -Dm755` derivation and verify `nix build .#statewright-gateway` produces a runnable binary
- [ ] 2.1b Package `sw-agent` + `statewright` (TUI) from source via `rustPlatform.buildRustPackage` against the workspace pinned to the same release commit (`cargoLock.lockFile = ./Cargo.lock`, rustc ≥ 1.85); verify `nix build .#sw-agent` and `nix build .#statewright-tui` both succeed
- [ ] 2.2 Create `modules/home-manager/ai/capability/statewright.nix` that adds all three binaries + a `statewright approve <instance-id> <event>` wrapper script to `home.packages` and verify `xi home switch .` on a scratch host places `statewright-gateway`, `sw-agent`, `statewright` (TUI), and `statewright approve` on PATH

## 3. Workflow authoring

- [ ] 3.1 Draft `workflows/support-ticket.json` matching statewright's `MachineDefinition` shape verbatim (`id`, `initial`, `states`, `guards`, `meta`, `interrupts`) with all 21 states listed in `agent-workflows/support-ticket/spec.md`, `initial: "discover"`, per-state `allowed_tools` derived from `docs/statewright/jira-ticket-fsm.md` §4; verify the file loads via `statewright_load_workflow` without error
- [ ] 3.2 Mark the 11 human-gated transitions from the spec with `requires_approval: true` on the FULL `TransitionDef` variant (per cheatsheet §3.2 — note: engine deserializes `requires_approval`, NOT `requires_human_approval`; the latter is a separate machine-level `MachineMeta` toggle); verify a dry-run instance emits a gate event for each gated transition
- [ ] 3.3 Add a JSON Schema at `workflows/support-ticket.schema.json` matching the `MachineDefinition` fields documented in `docs/statewright/cheatsheet.md` §1–§6; verify `ajv validate` accepts `support-ticket.json` against it and rejects a broken clone

## 4. Runtime wiring

- [ ] 4.1 Add a `.claude/settings.d/40-statewright-mcp.json` entry (managed via Nix) registering `statewright-gateway` as an MCP proxy with the support-ticket workflow discoverable; verify `claude --list-mcp` shows the gateway after `xi home switch .`
- [ ] 4.2 Ship workflow JSON files to `~/.claude/workflows/` from the capability module (via `home.file`); verify the file exists after switch and matches the source tree
- [ ] 4.3 Add slash command `.claude/commands/sw/ticket.md` that boots a workflow instance from `<ticket-id>`, writes `metadata.json` (ticket ID + root bead ID + try-dir path), and hands control to the agent; verify `/sw:ticket PLAT-TEST` creates an instance directory and logs `instance_created`
- [ ] 4.4 Enforce single-instance-per-ticket in the slash command (resume or refuse; never fork); verify a second `/sw:ticket PLAT-TEST` invocation resumes the existing instance rather than creating a parallel one

## 5. `jira-ticket` A/B toggle

- [ ] 5.1 Extend the `jira-ticket` skill to accept `--via-statewright` and, when passed, exec `/sw:ticket <ticket-id>` instead of the hardcoded path; verify invoking with the flag on a test ticket boots the workflow and leaves the hardcoded flow untouched without the flag
- [ ] 5.2 Document the flag in the skill's SKILL.md front matter and behavior section; verify the SKILL.md renders the flag under a "Migration" heading

## 6. Parity validation

- [ ] 6.1 Replay 3 archived tickets (pick from `try/*/PLAT-*/`) through the workflow and log per-ticket outcome diffs (bead DAG topology, MR states, ticket comment text) in `openspec/changes/statewright-workflow-layer/parity.md`; verify at least one archived ticket ran clean through workflow to `archive` state
- [ ] 6.2 Resolve any parity gaps by adjusting the workflow JSON (not the skill); verify parity.md ends with a "0 outstanding gaps" line before cutover

## 7. Observability

- [ ] 7.1 Implement the persistence wrapper that captures `sw-agent --json-events` stdout, prepends a monotonic `seq` (per instance) and ISO-8601 `ts`, and appends to `~/.cache/claude/statewright/<instance-id>/events.jsonl`; verify a scripted test produces monotonically increasing seq values and RFC3339-formatted ts strings across at least 100 events
- [ ] 7.2 Add a herdr pane recipe under `docs/statewright/observability.md` showing `tail -f events.jsonl | jq .` in a split; verify following the recipe surfaces live events during a `/sw:ticket` run

## 8. Cutover (BREAKING)

- [ ] 8.1 Flip the `jira-ticket` skill default to the workflow path and add a `--legacy` escape hatch; verify `jira-ticket PLAT-TEST` (no flag) boots the workflow and `jira-ticket PLAT-TEST --legacy` runs the hardcoded path
- [ ] 8.2 Refuse `jira-ticket` invocation outside a workflow instance without `--legacy` with a clear error that points to `/sw:ticket`; verify the error message names `/sw:ticket` and `--legacy`

## 9. Docs and memory

- [ ] 9.1 Update repo `CLAUDE.md` with a "Declarative workflows" section pointing to statewright + the support-ticket workflow; verify the section links to `docs/statewright/cheatsheet.md`
- [ ] 9.2 `bd remember "statewright is the workflow layer above skills; support-ticket is the first declarative skill; jira-ticket delegates via /sw:ticket"`; verify the note is retrievable via `bd search statewright`

## 10. Archive

- [ ] 10.1 Run `openspec validate statewright-workflow-layer --strict` and fix any warnings; verify the command exits 0
- [ ] 10.2 Run `openspec archive statewright-workflow-layer` to merge the deltas into `openspec/specs/agent-workflows/`; verify the change directory is removed and the specs directory now contains both `agent-workflows/spec.md` and `agent-workflows/support-ticket/spec.md`
