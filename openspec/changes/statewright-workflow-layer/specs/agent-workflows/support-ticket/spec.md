## Purpose

The concrete support-ticket workflow: encodes the shipped `jira-ticket` skill
FSM (21 states, 11 human gates, per-env deploy/verify lanes, related-MR
watch, awaiting-reporter) as a declarative statewright workflow. Defines
the migration path from the hardcoded skill to the workflow, cutover
criteria, and the artifact + async-wait + tab-claim contracts the workflow
must preserve.

## ADDED Requirements

### Requirement: Support-ticket workflow defines all 21 lifecycle states

The system SHALL ship a workflow `workflows/support-ticket.json` containing
these 21 states, matching the shipped `jira-ticket` pipeline: `discover`,
`set_capability`, `explore`, `propose_fix`, `fix`, `implement`, `ci_green`,
`review`, `merge`, `tag`, `deploy_dev`, `verify_dev`, `deploy_staging`,
`verify_staging`, `deploy_prod`, `verify_prod`, `answer`, `close`,
`awaiting_reporter`, `archive`, `watch_related_mr`. The `initial` state
SHALL be `discover`. Every state SHALL declare an `allowed_tools` list
scoped to that phase's actual toolset (per `docs/statewright/jira-ticket-fsm.md`
§4). `deploy_*` and `verify_*` states MAY additionally declare
`allowed_commands` to gate shell tools like `kubectl` / `helm` / `pup`.

#### Scenario: Only phase-appropriate tools are allowed per state

- **WHEN** the workflow is in state `discover` and the agent attempts to
  run a build tool
- **THEN** the gateway SHALL deny the call and emit a tool-denied event
  naming the current state's allowlist

### Requirement: Eleven human gates are declared explicitly

The workflow SHALL mark the following 11 transitions with
`requires_approval: true` (or place them behind
`meta.approval_mode: "manual"`), matching the shipped pipeline's mix of
explicit `blocking:human` beads and programmatic refusals:

1. `propose_fix → fix` — operator approves the fix design
2. `implement → ci_green` — human review of the implementation before CI
3. `review → merge` — merge decision
4. `merge → tag` — tag cut (skipped for non-tag-managed repos)
5. `verify_staging → deploy_prod` — prod gate
6. `verify_prod → answer` — reply drafting only after prod is healthy
7. `answer → close` — operator OK on the drafted reply before posting
8. `close → archive` — final Done transition
9. Any transition entering `awaiting_reporter` — pause for the reporter
10. Any transition into a `watch_related_mr` observation state
11. Any retry transition that would re-enter a failed state after a
    pipeline red

#### Scenario: Human gates block agent-driven transitions

- **WHEN** the agent invokes `statewright_transition` for any of the 11
  gated transitions above without an explicit approval
- **THEN** the gateway SHALL keep the workflow in the current state and
  emit a gate event

### Requirement: Per-environment deploy and verify lanes are distinct states

The workflow SHALL model `deploy_dev` / `deploy_staging` / `deploy_prod`
and `verify_dev` / `verify_staging` / `verify_prod` as separate states,
not a single parameterized state. `verify_prod` SHALL declare (via
`instructions` and/or a guard) a mandatory 1200-second baseline
stabilization wait before it can transition to `answer`. `verify_dev`
MAY skip the wait.

#### Scenario: verify_prod enforces the baseline wait

- **WHEN** the agent tries to transition out of `verify_prod` before the
  1200-second baseline has elapsed since state entry
- **THEN** the gateway SHALL refuse the transition and emit a gate event
  citing the remaining wait

### Requirement: Async-wait vs blocking:human is a modelled distinction

The workflow SHALL distinguish two idle modes: **async-wait** (waiting
for an external system: pipeline, deploy, verify baseline, related MR)
and **blocking:human** (waiting for an operator decision). Async-wait
SHALL be represented by an interrupt or a guard that polls the external
state; blocking:human SHALL be represented as `requires_approval`.
Both SHALL emit distinct event kinds in the JSONL stream so the tail-log
recipe can render them differently.

#### Scenario: A pipeline wait does not consume a human gate slot

- **WHEN** the workflow enters `ci_green` and the pipeline is still
  running
- **THEN** the workflow SHALL be marked async-wait, not human-gated, and
  the operator SHALL NOT be prompted to approve

### Requirement: Workflow instance metadata links to beads, try-dir, and Dust conversation

The system SHALL persist a `metadata.json` at the instance root recording:
the ticket ID, the root bead ID (from `bd`) tracking this ticket's work,
the try-directory path (`~/src/tries/<date>-<ticket>/`), and the Dust
conversation ID (per the shipped `jira-ticket` skill's Dust-mandatory
contract). Downstream tools SHALL read this file to correlate workflow
events with beads, artifacts, and prior Dust context.

#### Scenario: Metadata is written at instance creation

- **WHEN** `/sw:ticket PLAT-4012` creates a new instance
- **THEN** the system SHALL write `metadata.json` containing at least
  `{ticket, root_bead, try_dir, dust_conversation_id}` before the agent
  enters `discover`

### Requirement: Artifact set is versioned per instance

The workflow SHALL treat the following artifacts as first-class outputs of
their producing states, discoverable via `metadata.json`: `proof.md`
(from `explore`), `fix.md` (from `propose_fix`), `deploy.md` (from
`deploy_*`), `verify-<env>.md` (from `verify_*`), `answer.md` (from
`answer`), and `voice.md` (draft posts). Each artifact SHALL be written
into the try-directory linked from `metadata.json`; downstream states
SHALL consume them without re-computing.

#### Scenario: Explore output is discoverable by later states

- **WHEN** `explore` completes and writes `proof.md` to the try-directory
- **THEN** `metadata.json` SHALL list the artifact path and `propose_fix`
  SHALL be able to read it via that path

### Requirement: `/sw:ticket` slash command boots a workflow instance

The system SHALL install a slash command `/sw:ticket <ticket-id>` that:
creates a fresh workflow instance from `workflows/support-ticket.json`,
writes `metadata.json`, and hands the agent control at state `discover`.
Two invocations for the same `<ticket-id>` SHALL either resume the
existing instance or refuse with a clear error — never silently fork two
instances for the same ticket. The slash command SHALL enforce the
tab-claim invariant from the `jira-ticket` skill: one herdr tab per
ticket, no duplicates.

#### Scenario: A new ticket boots a fresh workflow

- **WHEN** the operator runs `/sw:ticket PLAT-4012` and no instance for
  `PLAT-4012` exists
- **THEN** the system SHALL create a new instance under
  `~/.cache/claude/statewright/support-ticket--PLAT-4012/`, seed it in
  `discover`, and log an instance-created event

#### Scenario: Re-invoking on an existing ticket resumes it

- **WHEN** the operator runs `/sw:ticket PLAT-4012` and an instance for
  `PLAT-4012` already exists
- **THEN** the system SHALL replay its event log, resume it at its
  current state, and refuse to create a parallel instance

### Requirement: `jira-ticket` skill supports an A/B migration toggle

The `jira-ticket` skill SHALL accept a `--via-statewright` flag. When the
flag is passed, the skill SHALL delegate execution to the support-ticket
workflow via `/sw:ticket <ticket-id>` instead of running its hardcoded
path. Without the flag, the skill SHALL run its current hardcoded path
unchanged (during migration).

#### Scenario: A/B toggle routes to the workflow

- **WHEN** an operator invokes `jira-ticket PLAT-4012 --via-statewright`
- **THEN** the skill SHALL boot the workflow instance for `PLAT-4012` and
  hand control off, without executing its hardcoded steps

### Requirement: Cutover flips the default and preserves an explicit legacy escape hatch

Once parity is validated (see design.md, §Migration Plan), the
`jira-ticket` skill SHALL flip its default to the workflow path. Passing
`--legacy` SHALL be the only way to re-run the hardcoded path.
**BREAKING**: after cutover, running `jira-ticket` outside a workflow
instance and without `--legacy` SHALL be refused with a clear error
pointing to `/sw:ticket`.

#### Scenario: Post-cutover, default is the workflow

- **WHEN** an operator invokes `jira-ticket PLAT-4012` after cutover
- **THEN** the skill SHALL boot the workflow instance and hand control
  off, matching the pre-cutover `--via-statewright` behavior

#### Scenario: Legacy escape hatch remains available

- **WHEN** an operator invokes `jira-ticket PLAT-4012 --legacy` after
  cutover
- **THEN** the skill SHALL execute its hardcoded path and skip the
  workflow

### Requirement: Related-MR watches are external observers, not blocking states

The workflow SHALL model `watch_related_mr` as an observer state that
consumes MR URLs from `related-mrs.txt` (produced by
`jiraai-review --deep`) but does NOT block the main happy path. Each
watched MR SHALL be tracked as its own instance-scoped async-wait timer
(polling via `glab`), reporting terminal states to the events stream
without preventing the ticket from progressing through `verify_prod` /
`answer` / `close`.

#### Scenario: A related-MR watch does not block the main lane

- **WHEN** the workflow is in `verify_prod` with a `watch_related_mr`
  timer still active for an unmerged related MR
- **THEN** the workflow MAY still transition to `answer` when the
  1200-second verify baseline elapses; the related-MR watch continues
  independently
