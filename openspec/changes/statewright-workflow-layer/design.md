## Context

See `proposal.md` for motivation. Current state:

- Skill pipelines encode implicit state machines in SKILL.md prose. The
  `jira-ticket` skill is the tallest example — 21 discrete states (per
  `docs/statewright/jira-ticket-fsm.md`), 11 human gates, per-env deploy
  and verify lanes, related-MR watchers, awaiting-reporter pause. The FSM
  is not machine-readable, so it drifts silently between SKILL.md,
  `.claude/commands/` entry points, and operator expectations.
- Task tracking and dispatch already live in `bd` (Dolt-backed beads) and
  gascity. Those systems own the *queue* — which unit of work runs next.
  What is missing is the *per-unit* execution FSM.
- `statewright` (Rust workspace of three binaries — `statewright-gateway`
  MCP proxy, `sw-agent` executor, `statewright` TUI) fits the missing
  layer: `MachineDefinition` JSON files + per-state `allowed_tools` +
  guards + human-approval (`meta.approval_mode` + per-transition flag) +
  JSONL event stream + pause/resume. It is orthogonal to `bd`/gascity
  (verified — NEEDLE would compete with them by owning the queue;
  statewright does not).
- Authoritative API references: `docs/statewright/cheatsheet.md`
  (workflow JSON shape, MCP tool signatures, CLI surface, packaging) and
  `docs/statewright/jira-ticket-fsm.md` (all 21 states + transitions +
  human gates + async-wait points, with source cross-refs). Both were
  written from source in Tier 0 of this change and are the source of
  truth for downstream tasks.

## Goals / Non-Goals

**Goals:**

- Declarative workflow files, versioned in Nix, discovered by name after a
  `xi home switch .`.
- Per-state tool allowlists enforced by the workflow engine — the agent
  physically cannot invoke an out-of-phase tool.
- Human approval gates at operator-designated transitions (default: any
  transition into a mutating phase).
- JSONL event stream per instance for replay + cross-session resume.
- Cutover-safe migration: A/B toggle first, cutover once parity is proven,
  legacy escape hatch preserved.

**Non-Goals:**

- Replacing `bd` or gascity. Statewright sits *inside* one bead's execution;
  the outer queue stays with beads.
- Modeling every skill as a workflow in this change. Only `support-ticket`
  ships; other skill migrations are future work.
- Cross-instance orchestration or parallel workflow instances of the same
  ticket (explicitly forbidden — see spec).
- A web UI. Terminal + JSONL only.

## Decisions

### 1. Statewright-gateway as MCP proxy, not CLI-invoked per step

**Choice:** Run `statewright-gateway` as an MCP server proxy registered in
`.claude/settings.d/`. Transitions happen via the `statewright_transition`
tool call. The gateway also enforces per-state tool + command allowlists at
the MCP proxy layer, which is stronger than what a shell-level CLI could
give us.

**Alternative considered:** Shell out to `sw-agent` per transition.
Rejected — loses per-tool-call allowlist enforcement (the agent could call
denied tools between transitions) and doubles the observability surface.

### 2. JSON workflow files match `MachineDefinition` verbatim

**Choice:** Workflow JSON follows statewright's `MachineDefinition` struct
verbatim (`id`, `initial`, `states`, `guards`, `meta`, `interrupts`,
`context`). Gateway config is the enveloping shape:
`{"definition": <MachineDefinition>, "upstream_servers": [...]}`.

**Alternative considered:** Custom pre-schema translated at load time.
Rejected — every hop is a chance for translation drift. Using upstream
shape verbatim also lets `statewright_load_workflow` accept our files
without a shim. `docs/statewright/cheatsheet.md` §1–§7 is the authoritative
field reference.

### 3. Human approval: `meta.approval_mode` + per-transition flag; wrapper for the CLI operator experience

**Choice:** Use `meta.approval_mode` for machine-wide gating and
`TransitionDef.requires_approval` for specific gates (both are
supported by statewright today). The `statewright` CLI does NOT expose an
`approve` subcommand — ship a thin wrapper `statewright approve
<instance-id> <event>` in the AI capability module that resolves the
pending gate via the gateway's hook endpoint (or via `statewright_transition`
with an approval token).

**Alternative considered:** Directly document `curl <gateway-hook-url>` in
place of a wrapper. Rejected — the wrapper hides the HTTP endpoint churn
and lets us swap the underlying mechanism (hook vs MCP tool) without
retraining operators.

### 4. Persistence layer synthesizes `seq` + `ts`; no upstream primitives

**Choice:** Statewright's JSONL events lack sequence numbers and
timestamps (ordering = stdout line order). We SHALL wrap
`sw-agent --json-events` with a persistence pipeline that prepends a
monotonic per-instance `seq` and ISO-8601 `ts` before appending to
`events.jsonl`. Instance storage stays at
`~/.cache/claude/statewright/<workflow>--<key>/`.

**Alternative considered:** Rely on line order only. Rejected — replay,
tail-with-jq, and cross-instance correlation all break silently if events
are ever reordered by log rotation or concatenation.

### 5. Migration via `--via-statewright` toggle, then cutover

**Choice:** Two-phase migration.
1. Ship the workflow + toggle. Hardcoded `jira-ticket` path stays default.
   Operator opts in per invocation with `--via-statewright`.
2. Cutover once ≥3 archived tickets replay through the workflow to
   `archive` with 0 outstanding outcome gaps (see parity.md).
   Flip default. Keep `--legacy` as an escape hatch for one release,
   then delete.

**Alternative considered:** Rewrite `jira-ticket` in place, no toggle.
Rejected — the skill is load-bearing; a bad cutover means rebuilding from
git history under pressure. Toggle lets us roll back with a flag flip.

### 6. Nix packaging: gateway from release zip, agent + TUI from source

**Choice:** Statewright is NOT in `llm-agents.nix` (verified against
`numtide/llm-agents.nix` on 2026-09-11). Package the three binaries in
two derivations:
- `statewright-gateway` → fetch prebuilt zip from the upstream
  `gateway-v*` release and `install -Dm755 statewright-gateway`. Matches
  upstream release cadence, no Rust build needed.
- `sw-agent` + `statewright` (TUI) → `rustPlatform.buildRustPackage`
  against the workspace pinned to a tagged release commit
  (`edition = "2024"` ⇒ rustc ≥ 1.85; `cargoLock.lockFile = ./Cargo.lock`).

**Alternative considered:** Build everything from source. Rejected —
extra Rust build time for a binary upstream already ships.

### 7. 21-state support-ticket, not 7

**Choice:** Model every state the shipped `jira-ticket` pipeline
encodes — 21 in total (per `docs/statewright/jira-ticket-fsm.md` §2).
Per-environment `deploy_*` and `verify_*` are distinct states.
`verify_prod` carries a mandatory 1200-second baseline wait; `verify_dev`
does not. `close` and `archive` are distinct terminal-adjacent states.
`watch_related_mr` and `awaiting_reporter` are observer/pause states,
not part of the linear happy path.

**Alternative considered:** Ship the 7-state simplified workflow first and
grow it. Rejected — a 7-state workflow cannot represent the shipped
pipeline's semantics, so parity runs would fail by construction and the
A/B toggle would not be actionable.

## Risks / Trade-offs

- **[Statewright is young / API may shift]** → Pin a specific tagged
  release in Nix; keep the workflow JSON schema separate from
  statewright's internal API so a breaking upstream change is a
  well-scoped update, not a full rewrite.
- **[Upstream events lack `seq` / `ts`, so replay + tail correlation
  depend on our persistence wrapper]** → The wrapper is a small,
  well-scoped script; test it explicitly in task 7.1. If we ever swap
  to an upstream that adds native fields, migrate by preferring
  upstream values when present.
- **[Gateway release cadence vs `sw-agent`/TUI source build could drift
  binary versions]** → Pin both to the same tagged release commit; add
  a smoke check that all three binaries report the same version after
  `xi home switch .`.
- **[MCP tool-call latency adds turn overhead]** → Every transition is an
  extra MCP roundtrip. Mitigation: batch state changes where safe (e.g.
  `discover` → `explore` on the same tool result). Measure first, optimize
  only if it hurts.
- **[Per-state allowlists reject a legitimate tool the operator forgot to
  list]** → Emit a `tool_denied` event with the current allowlist so the fix
  is a one-line JSON edit + `xi home switch .`. Do not add a "just this
  once" bypass — that undermines the point.
- **[JSONL event streams grow unbounded]** → Instance directories are cheap
  to `rm -rf`. Add a documented `statewright gc` command in a follow-up
  change; do not build it now.
- **[Cutover flips the default and breaks a muscle-memory `jira-ticket`
  invocation]** → **BREAKING** is called out in proposal + spec. Release
  notes must show the `--legacy` fallback and the cutover date.

## Migration Plan

1. **Ship the workflow layer, default off** — Nix packages statewright, ships
   `workflows/support-ticket.json`, registers MCP, installs `/sw:ticket` slash
   command. `jira-ticket` skill unchanged.
2. **Add `--via-statewright` toggle to `jira-ticket`** — inside the skill,
   branch on the flag: with it, exec `/sw:ticket <id>`; without it, current
   path.
3. **Parity runs** — replay 3 archived tickets through the workflow. Compare:
   bead DAG topology, MR outcomes, ticket comment content. Log deltas in a
   `parity.md` under the change dir until the change is archived.
4. **Cutover** — flip default. Ship `--legacy` escape hatch.
5. **Legacy removal** (out of scope for this change) — separate follow-up
   change once cutover has stuck.

**Rollback:** flip the default back via one-line skill edit + Nix switch.
Workflow files stay installed; instance state remains readable. No data loss.

## Open Questions

- None that would change specs, approach, or task breakdown at this scope.
  Follow-up changes will surface the tool allowlist per state as workflows
  are added.
