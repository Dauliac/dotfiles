## Why

The prior change `beads-go-migration-and-dolt-caps` dropped `mardi-gras` (`mg`) in favor of `beads-viewer` (`bv`) on user request. That call was reversed: user wants `mg` back **and** wants Claude to auto-open an `mg` split alongside the working pane whenever a beads-workflow phase kicks off (claim, `bd ready` loop, bulk create), so there's a live side-panel view of task state as work progresses. `bv` stays — this change is additive.

The trigger mechanism is **skill-driven**, not a Claude Code hook: a new `mg-watch` skill parallels the existing `ci-watch` / `k8s-watch` / `s3-watch` family, and the `beads` / `beads-flow` skill descriptions cross-reference it so the mandatory word-match self-check picks it up when beads work begins. This avoids the hook-based "fires blindly every session" cost and matches the project's established "TUI-per-domain via `tui-context`" pattern.

## What Changes

- Re-add `mardi-gras` to `pkgs.mardi-gras` via `inherit (llmAgentsPkgs) mardi-gras;` in `modules/packages/default.nix` (undoing the removal from the prior change).
- Re-add `mardi-gras` to the AI package list in `modules/home-manager/ai/packages.nix`. Keep `beads-viewer` — both TUIs coexist.
- Restore an `mg` alias in `modules/home-manager/aliases.nix`: `${pkgs.beads}/bin/bd sync --flush-only && ${pkgs.mardi-gras}/bin/mg`. Restoring the flush-and-launch pattern from the pre-migration alias, because Go bd does auto-flush on write but the passive JSONL export it reads is what `mg` observes.
- New skill: `modules/home-manager/ai/capability/skills/engineering/mg-watch/SKILL.md` — sibling of `ci-watch`/`k8s-watch`/`s3-watch`. Describes when to spawn `mg` in a herdr split via `herdr-tui launch`, the label conventions, the flush sidecar, the auto-close policy, and the deduplication check via `herdr-find` before spawning.
- Register `mg-watch` in the engineering skill list in `modules/home-manager/ai/capability/skills.nix`.
- Cross-reference: add one-line "Pair with `mg-watch` for a live side-panel view" pointer to the `beads` and `beads-flow` skill descriptions so the word-match self-check surfaces `mg-watch` automatically whenever beads work begins.

## Capabilities

### New Capabilities
- `ai-runtime/mg-tui-integration`: The rules that govern *when* and *how* an agent auto-opens the `mg` TUI alongside beads work — trigger phrases, split shape, label conventions, deduplication, flush cadence, auto-close policy. Complements the pure "which TUI is available" contract in `ai-runtime/beads` by covering the workflow integration surface.

### Modified Capabilities
- `ai-runtime/beads`: Add `mg` back to the shipped-TUI set. The `beads-viewer TUI is available` requirement's second scenario (`mg binary is not present`) is inverted — the system now DOES ship `mg`. `bv` stays available in parallel.

## Impact

**Affected nix modules**:
- `modules/packages/default.nix` — add `mardi-gras` to the `inherit (llmAgentsPkgs) ...` block (one line).
- `modules/home-manager/ai/packages.nix` — add `mardi-gras` back to the AI package list (one line).
- `modules/home-manager/aliases.nix` — add `mg` alias with the flush-before-launch pattern (three lines with comment).
- `modules/home-manager/ai/capability/skills.nix` — register `"mg-watch"` in the engineering skill list.

**New files**:
- `modules/home-manager/ai/capability/skills/engineering/mg-watch/SKILL.md` — the trigger skill (~60 lines following the shape of `ci-watch`, `k8s-watch`).

**Modified files**:
- `modules/home-manager/ai/capability/skills/engineering/beads/SKILL.md` — one-line cross-reference in the description or "Composes with" section.
- `modules/home-manager/ai/capability/skills/engineering/beads-flow/SKILL.md` — one-line cross-reference so the DAG-driver naturally arms the side-panel.

**Not affected**:
- The `dolt-beads` systemd user service — `mg` reads `.beads/issues.jsonl` directly (passive export), not the sql-server.
- The `beads-config.nix` hook-guard module — hook enforcement is orthogonal to viewer TUI selection.
- The archived state of `beads-go-migration-and-dolt-caps` — that change is closed as complete; this is a follow-up with its own openspec artifacts, per the project's design → beads → apply flow.

**External dependencies**:
- `pkgs.mardi-gras` (`quietpublish/mardi-gras`, `mg` binary) — already available via `llm-agents.nix`, was inheritable in the prior change and just needs re-adding.
- `pkgs.herdr-tui` wrapper — already on PATH via home-manager (`herdr-tui --help` verified during proposal drafting).
