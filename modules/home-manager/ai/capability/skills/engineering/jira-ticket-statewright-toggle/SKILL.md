---
name: jira-ticket-statewright-toggle
description: Addendum to the `jira-ticket` skill. When the operator's request contains `--via-statewright` (or `--statewright`) alongside a ticket ID, delegate to the declarative statewright workflow at `/sw:ticket <ticket-id>` and STOP executing the hardcoded `jira-ticket` pipeline. Trigger on: any `jira-ticket`-style request that carries `--via-statewright`, `--statewright`, `via statewright`, or "route through statewright". Also trigger after cutover on any bare `jira-ticket <TICKET-ID>` invocation unless `--legacy` is present. Preserves the `--legacy` escape hatch that runs the hardcoded jira-ticket path.
---

# jira-ticket-statewright-toggle — route to `/sw:ticket` on flag

The shipped `jira-ticket` skill orchestrates support-ticket resolution
through a hardcoded pipeline of `jira-explore` → `jira-fix` → `jira-answer`
with per-step Dust + beads + herdr tab handoff. The
`statewright-workflow-layer` OpenSpec change adds a declarative FSM
implementation of that pipeline as `workflows/support-ticket.json`,
booted via the `/sw:ticket <ticket-id>` slash command and gated by the
`statewright-gateway` MCP proxy.

This addendum skill lives beside `jira-ticket` and adds the routing
policy without touching the original skill file. When both skills load
in the agent context, this one's rules take precedence for the toggle.

## Routing decision (evaluate BEFORE any `jira-ticket` step)

Given the operator's most-recent request text and a ticket ID `<T>`:

| Condition | Action |
|---|---|
| Request contains `--via-statewright` or `--statewright` (case-insensitive) | Invoke `/sw:ticket <T>` and STOP. Do not run `jira-ticket` steps. |
| Request contains `--legacy` | Skip this addendum. Run `jira-ticket` as documented (hardcoded path). |
| Neither flag, pre-cutover | Run `jira-ticket` as documented. The workflow layer is opt-in. |
| Neither flag, post-cutover (see cutover marker below) | Invoke `/sw:ticket <T>` and STOP. Legacy path is only reachable via `--legacy`. |

**Cutover marker**: `~/.claude/workflows/.statewright-default` — presence
of this file (shipped by the Nix capability module once the cutover
bead do-8iy closes) flips the "no flag" default from `jira-ticket` to
`/sw:ticket`. Before that file exists, "no flag" keeps the legacy path.

## Refuse (report + stop, do not silently continue)

- Both `--via-statewright` and `--legacy` in the same request — the operator's
  intent is ambiguous. Ask which to run.
- `--via-statewright` without a resolvable ticket ID — `/sw:ticket` requires
  one. Ask the operator to supply it.
- `--via-statewright` from a herdr tab whose label does not match the ticket
  (per the tab-claim invariant in the `sw:ticket` slash command). Do not
  bind the workflow to the wrong operator context.

## How the delegation actually happens

`/sw:ticket <T>` is a Claude Code slash command (see
`.claude/commands/sw/ticket.md`). Invoking it from the agent means
issuing the text `/sw:ticket <T>` — the harness expands it into the
command's prompt, which then runs the boot sequence (validate → tab
check → resume-if-exists → seed try-dir/Dust/bead/tab → write
`metadata.json` → `statewright_load_workflow`). All subsequent tool
calls in the session are proxied through `statewright-gateway` and
constrained by the workflow's per-state `allowed_tools`.

## Contract with the `jira-ticket` skill

This addendum does not modify the `jira-ticket` file. Post-cutover, the
`jira-ticket` skill still exists and remains reachable via `--legacy`;
this addendum only *routes* invocations, it does not *replace* the
skill. If the addendum is not loaded (e.g. removed from the AI
capability module), `jira-ticket` reverts to its historical behavior
with no toggle awareness — the routing policy is soft, not hard-wired
in the underlying skill.

## Composes with

- **jira-ticket** — the underlying orchestrator this skill routes around.
- **sw:ticket** slash command — the entry point this skill delegates to.
- **statewright** capability module (`modules/home-manager/ai/capability/statewright.nix`) — provides the gateway + workflow files this skill depends on.
- **beads** — root bead + phase beads are still created; `/sw:ticket`
  and `jira-ticket` both stamp the same bead template so the tracker is
  workflow-agnostic.
