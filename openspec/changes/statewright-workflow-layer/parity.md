# Parity runs — statewright vs hardcoded jira-ticket

Prerequisites before running:
- `xi home switch .` on this host (installs `statewright-gateway`, `sw-agent`,
  `statewright` TUI, `statewright-approve` wrapper, MCP registration, workflows).
- Verify `statewright-gateway --help` on PATH.
- Verify `claude --list-mcp` shows `statewright`.
- Pick 3 archived tickets from `~/src/tries/*/PLAT-*/` that ran through the
  hardcoded `jira-ticket` pipeline to completion. Note their IDs below.

## Method (per ticket)

For each ticket `<T>`:

1. **Snapshot the hardcoded run** (already in the try-dir): note the final
   bead DAG state (`bd list --label ticket:<T>`), MR IID + state (from
   `metadata.json` / try-dir MR notes), and the final Jira comment text
   posted to the reporter.
2. **Run through statewright** in a scratch instance:
   `/sw:ticket <T>` — either resume an existing instance directory (if the
   operator lets it reuse the try-dir Dust conversation) OR clear the
   statewright instance dir first (`rm -rf ~/.cache/claude/statewright/support-ticket--<T>`).
3. **Compare outcomes**:
   - Bead DAG topology — labels, dependencies, closed/open ratio at end.
   - MR states — same MR? Same title/desc? Same reviewers?
   - Ticket comment text — same close-out reply, or equivalent per ste100 rules?
   - Any state the workflow entered that the hardcoded path did NOT (or vice
     versa)?
4. **Log the diff below**. Structure per ticket:

```markdown
### <TICKET-ID>

- **Hardcoded outcome**: <summary>
- **Statewright outcome**: <summary>
- **Deltas**:
  - <bullet>
- **Verdict**: PARITY | DELTA — WORKFLOW CHANGE NEEDED | DELTA — BENIGN
```

## Ticket 1 — <TICKET-ID>

_TBD after operator run_

## Ticket 2 — <TICKET-ID>

_TBD after operator run_

## Ticket 3 — <TICKET-ID>

_TBD after operator run_

## Summary

_TBD_

**Outstanding gaps**: TBD — this line must read `0 outstanding gaps` before
task 6.2 closes and cutover (task 8.1) can begin.
