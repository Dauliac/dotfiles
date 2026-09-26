## Purpose

Declarative FSM layer for skill pipelines: workflows are JSON `MachineDefinition`
files served by a `statewright-gateway` MCP proxy, defining states,
per-state tool + command allowlists, transition guards, human approval
gates (via `meta.approval_mode` and per-transition `requires_approval`),
and JSONL event streams — so any long-running skill pipeline becomes
inspectable, guarded, replayable, and resumable across sessions.

## ADDED Requirements

### Requirement: Workflow definition follows statewright's MachineDefinition shape

The system SHALL define each workflow as a JSON file with the exact top-level
keys statewright's engine deserializes: `id`, `initial`, `states`, `guards`
(optional), `meta` (optional), `interrupts` (optional), and `context`
(optional). Each `states` entry SHALL be a `StateDef` with an `on` map of
event → `TransitionDef`, optional `allowed_tools` / `disallowed_tools`,
optional `instructions`, and optional `max_iterations`, `safe_next`,
`allowed_commands`, `max_files_per_state`. The system SHALL NOT declare
non-existent keys (e.g. `schema_version`, `on_enter`, `on_exit`) on the
top-level or on `StateDef`. Versioning metadata SHALL live under `meta.extra`.

#### Scenario: A workflow file conforms to the real MachineDefinition schema

- **WHEN** a workflow JSON is instantiated via `statewright_load_workflow`
  or served from a gateway config
- **THEN** its top-level keys SHALL be a subset of
  `{id, initial, states, guards, meta, interrupts, context}` and every
  transition SHALL reference a state present in `states`

#### Scenario: Tool invocation outside the state's allowlist is blocked

- **WHEN** an agent proxied by `statewright-gateway` in state `S` tries to
  invoke a tool not listed in `S.allowed_tools` (or listed in
  `S.disallowed_tools`)
- **THEN** the gateway SHALL refuse the tool call and emit a corresponding
  event in the JSONL stream naming the current state, requested tool, and
  the effective allowlist

### Requirement: Transitions fire via the statewright MCP tool surface

The system SHALL expose transitions through the MCP tools provided by
`statewright-gateway`: at minimum `statewright_transition` (with `event`
name plus optional `data` payload), `statewright_get_state`,
`statewright_pause`, `statewright_deactivate`, `statewright_get_status`. A
call to `statewright_transition` SHALL evaluate matching transitions'
guards in declaration order and apply the first whose guard passes; the
tool SHALL return a structured rejection listing candidate transitions
and their guard results when none passes.

#### Scenario: A valid transition is applied

- **WHEN** the agent calls `statewright_transition` with `event` matching a
  transition whose guard passes
- **THEN** the engine SHALL move to the target state and emit a
  transition-applied event in the JSONL stream

#### Scenario: A transition is rejected due to guard failure

- **WHEN** the agent calls `statewright_transition` with an event where every
  matching transition's guard fails
- **THEN** the engine SHALL leave state unchanged and return the list of
  attempted guards with their false conditions

### Requirement: Human approval gates block automated transitions

The system SHALL express human approval two ways as statewright supports
them today: (1) machine-wide via `meta.approval_mode` (values `manual` |
`auto` | undefined) and (2) per-transition via the full `TransitionDef`
variant's `requires_approval: true`. A workflow that needs a mix
SHALL declare `approval_mode` and mark the specific gated transitions.
When a gated transition would fire, the engine SHALL pause the workflow
until an operator uses a documented approval path (see next requirement).

#### Scenario: Automated approval attempt is blocked on a gated transition

- **WHEN** an agent invokes `statewright_transition` for a transition marked
  `requires_approval: true` (or all transitions when
  `approval_mode: "manual"`)
- **THEN** the engine SHALL keep the workflow in the current state, emit a
  gate event in the JSONL stream, and return a pending status

#### Scenario: Human approves and workflow resumes

- **WHEN** an operator invokes the documented approval path (see the
  Approval Interface requirement)
- **THEN** the pending transition SHALL apply and the engine SHALL emit the
  transition-applied event

### Requirement: Approval interface is a first-class operator command

Statewright's CLI does NOT ship a first-class `approve` subcommand, so this
project SHALL provide `statewright approve <instance-id> <event>` as a thin
wrapper that resolves the pending gate on a running instance (e.g. via the
gateway's HTTP hook endpoint or by calling `statewright_transition` with an
approval token). The wrapper SHALL live in the AI capability module and be
installed on PATH after `xi home switch .`.

#### Scenario: Approve wrapper resolves a pending gate

- **WHEN** an instance is paused waiting for approval on event `E` and the
  operator runs `statewright approve <id> E`
- **THEN** the wrapper SHALL call the gateway (or MCP tool) so the engine
  applies the pending transition, or return a non-zero exit with the
  gateway's rejection reason if the approval is rejected

### Requirement: Workflow instances persist events for resume and replay

The system SHALL persist every JSONL event line emitted by
`sw-agent --json-events` (or the gateway's stream) to a per-instance file
at `~/.cache/claude/statewright/<instance-id>/events.jsonl`. The system
SHALL synthesize a monotonic sequence number and an ISO-8601 timestamp on
each persisted line, because upstream events do not carry either field.
Restarting an instance SHALL rebuild its state by replaying its event log
via the gateway's load / resume flow. Deleting the instance directory
SHALL be a supported clean-slate operation.

#### Scenario: Events are persisted with synthesized sequence and timestamp

- **WHEN** `sw-agent` emits an event to stdout for an instance
- **THEN** the persistence layer SHALL prepend a monotonic `seq` (0-indexed
  per instance) and an ISO-8601 `ts` field and append the resulting JSON
  object as a line to the instance's `events.jsonl`

#### Scenario: An interrupted workflow resumes to the correct state

- **WHEN** an operator restarts a workflow instance whose event log ends
  with a transition-applied event moving it to state `S`
- **THEN** the engine SHALL rebuild the instance in state `S`, replay any
  pending approvals, and accept new tool calls under `S.allowed_tools`

### Requirement: Workflow definitions are shipped declaratively via Nix

The system SHALL package workflow JSON files as part of the AI capability
set. Nix SHALL install them into a known location (`~/.claude/workflows/`)
where the gateway discovers them by filename. The system SHALL also
package the gateway config file that references those workflows and
declares upstream MCP servers. Editing a workflow SHALL require a Nix
switch — in-place mutation of installed workflow files is not supported.

#### Scenario: A new workflow is discovered after a switch

- **WHEN** a new `workflows/<name>.json` is added to the Nix module and the
  user runs `xi home switch .`
- **THEN** the gateway SHALL discover it via `statewright_list_workflows`
  and the slash command surface SHALL expose it without further
  configuration

### Requirement: Statewright binaries are Nix-packaged from upstream releases and source

The system SHALL package the `statewright-gateway` binary from the upstream
release zip (Linux x86_64 asset from `github.com/statewright/statewright`
releases) and the `sw-agent` and `statewright` (TUI) binaries from source
via `rustPlatform.buildRustPackage` against the workspace (Rust edition
2024 ⇒ rustc ≥ 1.85). The system SHALL NOT rely on `llm-agents.nix` for
a statewright package, because upstream does not currently ship one.

#### Scenario: Gateway is available from PATH after switch

- **WHEN** the operator runs `xi home switch .` on a host with the AI
  capability enabled
- **THEN** `statewright-gateway`, `sw-agent`, and `statewright` (TUI) SHALL
  be on PATH

### Requirement: Workflow observability via JSONL event stream

The system SHALL provide a documented way to tail a running instance's
event stream from the terminal. The stream SHALL include, at minimum:
state transitions, tool allowed/denied decisions, transition attempts
(with guard outcomes), approval requests/grants, and errors. Every
persisted event SHALL carry the synthesized monotonic `seq` and ISO-8601
`ts` fields required by the persistence requirement.

#### Scenario: Operator inspects a running workflow

- **WHEN** an operator runs the documented tail command against an active
  instance
- **THEN** the terminal SHALL show events as they occur, and past events
  SHALL be readable from `events.jsonl` in the instance directory
