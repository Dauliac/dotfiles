## Context

See `proposal.md` for motivation. Facts that shape the approach, gathered during proposal drafting:

- `pkgs.mardi-gras` is available in the pinned `llm-agents.nix` flake input (`quietpublish/mardi-gras` v0.32.0, binary `mg`). The prior change removed it from the `inherit (llmAgentsPkgs) ...` list in `modules/packages/default.nix:60`; a one-line re-add reinstates it.
- The `herdr-tui` wrapper is on PATH (`/home/juliendauliac/.nix-profile/bin/herdr-tui`, shipped by the `herdr` package from `llm-agents.nix`). Its help output enumerates `launch`, `grid-open`, `grid-add`, `grid-close` subcommands and the `--auto-close-{on-idle,when,timeout}` / `--keep` / `--label` / `--ratio` flags. **There is no `herdr-tui find` subcommand** — dedup needs to happen via the separate `herdr-find` skill (which invokes `herdr` primitives), not through `herdr-tui`.
- Existing sibling skills (`ci-watch`, `k8s-watch`, `s3-watch`) all follow the pattern: single `herdr-tui launch --label X --auto-close-... -- <cmd>` at ~40-80 lines each. The `mg-watch` skill will mirror this shape verbatim.
- The pre-migration `mg` alias (`modules/home-manager/aliases.nix` at HEAD~) was `"${pkgs.beads}/bin/bd sync --flush-only && ${pkgs.mardi-gras}/bin/mg"`. Its comment noted that `mg` reads `.beads/issues.jsonl` (passive export), so a flush was needed pre-launch to freshen the file. This is still true with Go bd — `bd export` writes JSONL; other writes only update the Dolt DB. Restoring the alias verbatim is safe.
- `mg` reads the JSONL export, NOT the Dolt sql-server, so this change does not depend on the `dolt-beads.service` state and is orthogonal to embedded-vs-server-mode.
- Skill loader lives in `modules/home-manager/ai/capability/skills.nix:5` (engineering array) → `mkSkill "engineering" "<name>"` walks `skills/engineering/<name>/` recursively and materializes files into `~/.claude/skills/<name>/`. Registration is a one-line addition alphabetically sorted around `k8s-watch`.

## Goals / Non-Goals

**Goals:**
- Re-ship `pkgs.mardi-gras` and its `mg` alias with the same flush-before-launch shape as the pre-migration state.
- Introduce a `mg-watch` skill that mirrors `ci-watch` / `k8s-watch` / `s3-watch` — same size, same trigger-phrase-in-frontmatter shape, same `herdr-tui launch` primitive.
- Wire cross-references into `beads` and `beads-flow` so the word-match self-check pulls in `mg-watch` when beads work begins.

**Non-Goals:**
- Reversing the Rust → Go bd migration. That's the settled state from the prior change; `mg` is a viewer, backend choice is orthogonal.
- Automating `mg-watch` via a Claude Code hook (`SessionStart`, `PreToolUse`). Rejected by user in favor of skill-driven triggering; hook approach fires blindly whether or not beads work happens this session.
- Building a `grid-open` layout with `mg` + `bv` side-by-side. Users can invoke that manually via `tui-context`; not part of the auto-trigger contract.
- Modifying `dolt-beads.service` — `mg` reads JSONL, doesn't touch the sql-server.
- Reversing hook-guard behavior. `.git/hooks/*` stays lefthook-owned; `mg-watch` is a viewer-only concern.

## Decisions

### D1. Skill-driven trigger via word-match, not a Claude Code hook

Rejected the hook approach because:
- `SessionStart` hooks fire every session in every `.beads/`-carrying repo, regardless of whether the session actually touches beads work. Wastes screen real estate for grep/read/other sessions.
- `PreToolUse` matcher on Bash commands running `bd` is more selective but adds a runtime tax on every Bash call and is harder to make idempotent.
- Skill-driven trigger only fires when the agent is *deciding* to do beads work (word-match matches "bd ready", "bd claim", "beads workflow"). The dedup check happens once, at decision time, not on every session bootstrap.

Design: `mg-watch` sits in the engineering skills list; its frontmatter `description` includes trigger phrases (`bd ready`, `bd claim`, `beads workflow`, "open mg split", "side-panel view"). The `beads` and `beads-flow` skill descriptions get one-line "Pair with mg-watch" cross-references so their triggers naturally surface `mg-watch` too.

**Alternative considered**: `PreToolUse` hook. Rejected per above.

### D2. `--auto-close-on-idle 900` (15 minutes), no `--auto-close-when` predicate

The `ci-watch` sibling uses `--auto-close-when` because CI pipelines have a clear "done" state (`success`|`failed`|`canceled`|`manual`). Beads work has no equivalent — the work is *ongoing* while the agent is running, and the pane is glanced at (not focused) between glances.

- `--auto-close-on-idle` default 60s is way too aggressive for a side panel — it would close before the agent even finishes its first bead.
- `--keep` never auto-closes and leaks panes across long sessions.
- 900 seconds (15 min) is a compromise: long enough that a user can walk away for coffee and come back; short enough that abandoned panes clean up.

**Alternative considered**: `--auto-close-timeout 7200` (2 hours hard cap). Rejected: idle-based close is the right semantics; if a user is actively glancing, `--auto-close-on-idle` extends automatically; if not, 15 minutes is plenty.

### D3. Dedup by label prefix `mg-<repo-slug>`, checked via `herdr` primitives

`herdr-tui` has no `find` subcommand, so dedup uses the sibling `herdr-find` skill's primitives (or the raw `herdr pane list --workspace` + jq filter on label). The `mg-watch` SKILL.md includes the exact one-line pre-launch check.

**Alternative considered**: no dedup, spawn duplicates. Rejected: workspace clutter compounds fast, especially in long agent sessions.

### D4. Flush-before-launch pattern preserved

Restoring the pre-migration alias `bd sync --flush-only && mg`. Go bd auto-flushes the JSONL on `bd sync` per its docs (`bd import --help` in prior session confirmed the export→JSONL pipeline). Without the flush prefix, `mg` shows stale state up to the last bd sync.

`mg-watch`'s `herdr-tui launch --` command mirrors this: `bd sync --flush-only && mg` inside the split, so the launch pane runs the flush itself.

**Alternative considered**: rely on a systemd path unit that watches the Dolt DB and re-flushes. Rejected: complex, requires reliable inotify on the Dolt storage, out of scope for a viewer-integration change.

### D5. Cross-references embedded in existing skill descriptions, not new skill files

The `beads` and `beads-flow` skill descriptions need to mention `mg-watch` so the word-match self-check surfaces both. Two options:

- Extend the `description:` frontmatter field (loaded into context always).
- Add a "Composes with" body section (loaded only after skill triggers).

Choice: **both, but the frontmatter one-liner is the load-bearing one** since it's what the word-match sees. The body cross-reference is documentation-only.

## Risks / Trade-offs

- **[Skill-loader budget]** → mg-watch frontmatter must stay under 500 chars per `mm-skills-skill-creation` guidance. Task 3 verifies with `wc -c` on the extracted `description:` line.
- **[Dedup false-negative if `herdr-find` primitives don't handle label globs]** → design test in task 4.3 confirms `herdr pane list` returns the label field and that a shell `grep -q "^mg-"` filter works. If not, fall back to a broader check (any label starting with `mg`).
- **[`mg` doesn't understand Go bd's JSONL variant]** → verified in the prior change's do-10u.27 that `bv` reads the current JSONL cleanly; `mg` and `bv` consume the same file. Confidence is high but not perfect — smoke test in task 5.2 catches regressions before closing.
- **[User invokes `mg-watch` outside a beads repo]** → skill should no-op gracefully (test `-d .beads` and bail). Task 4.4 verifies.
- **[Flush cost adds latency to every `mg-watch` fire]** → `bd sync --flush-only` on a ~150-issue DB is measured at ~80ms in the prior session's load test. Negligible.

## Migration Plan

**Order:**
1. Land the package re-add (task 2.x) so `pkgs.mardi-gras` and the `mg` alias exist after the next `xi home switch`.
2. Land the `mg-watch` SKILL.md + skills.nix registration (task 3.x).
3. Land cross-references in `beads` / `beads-flow` (task 4.x).
4. Deploy: `xi home switch .`
5. Verify: `command -v mg` resolves, `~/.claude/skills/mg-watch/SKILL.md` exists, agent word-match self-check surfaces `mg-watch` on a fresh `bd ready` invocation (manual test, task 5.x).

**Rollback:**
- Revert the commit; `xi home switch` reverts. `mg-watch` skill file vanishes from `~/.claude/skills/`, `pkgs.mardi-gras` becomes unavailable, `mg` alias unbound.

## Open Questions

None that materially change the specs, approach, or task breakdown.
