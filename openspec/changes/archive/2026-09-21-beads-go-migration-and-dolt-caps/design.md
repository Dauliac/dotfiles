## Context

See `proposal.md` for motivation. Current state summarized here only where it shapes the approach:

- `pkgs.beads` = `symlinkJoin { paths = [ llmAgentsPkgs.beads-rust ]; postBuild = "ln -s $out/bin/br $out/bin/bd"; }` (`modules/packages/default.nix:42-51`). Rust `br`, SQLite (frankensqlite), no Dolt.
- A Dolt process is currently running on this host with default tuning (idle stats collector, 8h `read_timeout_millis`, unbounded `max_connections`). Its lifecycle is not managed by any nix module in this repo, and its config is not the file at `.beads/dolt/config.yaml` (which is a template only). Whatever component starts it is out of scope; this change replaces it with a fully managed, resource-capped service.
- `.git/hooks/{pre-commit,pre-push,prepare-commit-msg}` are lefthook shims. `.beads/hooks/*` files exist but their content has been overwritten to lefthook shims (see `git status` — `.beads/hooks/pre-commit.legacy` and `.beads/hooks/pre-commit.old` were removed in this in-progress branch). A future `bd init` would re-arm the clobber.
- `llm-agents.nix` (input `numtide/llm-agents.nix`, pinned to `/nix/store/n8mwajxj7...-source`) provides: `beads` (Go, gastownhall/beads v1.2.2), `beads-rust` (Rust), `beads-viewer` (Go, Dicklesworthstone/beads_viewer v0.24.1), and `dolt` (v2.3.2, patched from nixpkgs to require Go 1.26+). `mardi-gras` and `gascity` are also in the flake but are not consumed by this change.
- Existing repo pattern for `hooks.SessionStart` claude-code hooks: `modules/home-manager/ai/scratch.nix:37`. Same merge machinery is available for the beads hook if we ever add cross-machine sync (deferred to a follow-up change per the user's decision).

## Goals / Non-Goals

**Goals:**
- Ship Go `bd` so `bv` (beads-viewer) works and Dolt tuning is meaningful.
- Cap the Dolt process so idle CPU stays under 5% on a laptop.
- One authoritative Dolt sql-server on this host; every agent connects to it (`127.0.0.1:32867`).
- One authoritative git-hook manager per repo (lefthook); beads never touches `.git/hooks/`.
- Fully reproducible from the flake for the beads + Dolt + viewer trio.

**Non-Goals:**
- Cross-machine beads sync via Claude Code hooks. Deferred to a follow-up change (`beads-cross-machine-sync`); user confirmed cross-agent (same-machine) is the current concern.
- Packaging or configuring `gascity` / `gc`. User has confirmed they no longer need it. Any residual `.gc/` state on disk is separate cleanup, out of scope.
- Shipping `mardi-gras` / `mg`. User has confirmed `bv` (beads-viewer) alone is sufficient.
- Replacing lefthook with HK. HK's headline feature (per-file parallel write locks) doesn't apply to this repo's hook set (`nix fmt`, `nix flake show`, `task build` don't collide).
- Automated data migration from Rust SQLite `.beads/beads.db` to Go Dolt `.beads/embeddeddolt/`. One-shot manual per repo with a verification gate.
- Adding beads sync commands to `lefthook.yaml`. Beads state is authoritative in the local Dolt DB; no hook touches beads.

## Decisions

### D1. Single shared Dolt server, not one per repo

Dolt exposes one `data_dir` per sql-server; subdirectories under it are separate databases (dolthub `2024-12-10-config-yaml` post + `2021-11-22-supporting-multiple-dbs` post). Gas City's own model is one server serving all rigs. We follow the same model:

- Managed `data_dir = ~/.local/share/dolt-beads`
- Each repo's `.beads/embeddeddolt/` is a subdir (symlinked or moved) under that data_dir, addressed via `USE <repo>;` inside SQL
- One `systemd.user.services.dolt-beads` unit, one open port `127.0.0.1:32867`

**Alternatives considered:**
- **Per-repo systemd unit template** (`dolt-beads@<repo>.service`) — cleaner isolation, but N units × N GB heap × N cgroup overhead. Rejected: user is solo, no isolation benefit worth the multiplier.
- **Per-invocation embedded Dolt** (no service) — zero idle CPU, but 200–500 ms per `bd` call cold-start, and re-opens journal each time (unclean-stop risk per dolt#3176 lineage). Rejected: incompatible with the "multi-agent cross-agent sync" goal — every agent would race on the DB directory lock.

### D2. Cap Dolt with cgroup soft + hard limits, not just quotas

`MemoryHigh=512M` is a **soft** throttle (kernel slows the cgroup, no kills); `MemoryMax=1G` is the **hard** backstop (OOM killer). Dolt does not swap gracefully — Go's arena allocator + `MemorySwapMax=0` keeps the memory picture predictable. Combine with `GOGC=400` + `GOMEMLIMIT=768MiB` env so Go's own runtime GC fires *before* the kernel throttles.

**Rationale for the numbers**:
- `GOMEMLIMIT=768MiB` sits below `MemoryHigh=512M`? No — `GOMEMLIMIT` is the Go heap soft target; the process RSS runs 1.2–1.5× above it for stack + shared libs. `GOMEMLIMIT` at 768 MiB keeps heap under ~1 GiB observed RSS, which is what `MemoryMax` catches.

**Wait** — that's the wrong sign. Fix: `MemoryHigh=512M` is too aggressive if `GOMEMLIMIT=768M` — Go would consistently exceed the soft cap and eat throttle. Corrected sizing: `MemoryHigh=1G`, `MemoryMax=1.5G`, `GOMEMLIMIT=768MiB`. Task 4 must validate this by running the service under load and reading `systemd-cgtop` before final numbers land.

- `CPUQuota=50%` on a 4-core laptop = enough for interactive `bd` latency, hard cap prevents runaway.
- `Nice=10`, `IOSchedulingClass=best-effort priority=7` — de-prioritize vs foreground apps but don't fully starve.
- `TimeoutStopSec=30s`, `KillSignal=SIGTERM` — Dolt needs a clean shutdown to flush the journal; a fast SIGKILL loses in-flight writes.

**Alternatives considered:**
- `MemoryMax` alone (no `MemoryHigh`) — OOM-kills on load spikes, loses writes. Rejected.
- `Type=notify` + `WatchdogSec=` — Dolt doesn't call `sd_notify(READY=1)`, per the official dolthub systemd example (`docs.dolthub.com/introduction/installation/application-server`). Falls back to `Type=simple` + `Restart=on-failure`.

### D3. `bd init --skip-hooks` + activation-time `bd hooks uninstall` guard

**Finding from research task 1.1 (bead do-10u.1)**: Go bd has no persistent YAML config key that disables hook installation. Verified against `gastownhall/beads` `docs/reference/configuration.md`, `docs/reference/git-integration.md`, and `internal/hooks/hooks.go` on `main` at 2026-09. The YAML surface exposes `no-git-ops` as an individual key, but per the docs it only affects `bd prime`'s session-close protocol — not the hook installer. Legitimate mechanisms are:

- `bd init --skip-hooks` — one-shot at init: no hooks installed
- `bd hooks uninstall` — retroactive, removes the shims from `.git/hooks/`
- `bd hooks status` — reports whether hooks are currently installed

**Bonus finding**: Go bd detects lefthook (and hk, husky, pre-commit, prek) as first-class external hook managers. `bd doctor --fix` reinstalls bd's hooks with `--chain` so lefthook's hooks keep running. This is the *upstream-recommended* coexistence path. We deliberately DO NOT choose it because the user's requirement is "no bd hooks in `.git/hooks/`" — even chained. So we use `--skip-hooks` + `bd hooks uninstall` guard instead.

**Enforcement mechanism (revises earlier plan)**:
- `bd init --skip-hooks` at first-init time (documented per-repo bootstrap)
- Home-manager activation script (or Claude Code `SessionStart` hook, see task 4.2) that, for each `.beads/` dir found in the working tree, runs `bd hooks status` and calls `bd hooks uninstall` if the shims are present
- Task 4.1's original goal ("write `.beads/config.yaml` with hooks-disabled directive") is not achievable via config alone — 4.1 becomes "ensure the uninstall guard is wired for every repo the user works in"

**Not chosen: `bd init --stealth`** — that flag also disables `AGENTS.md` writes, which we want for skill discoverability (skills read AGENTS.md). `--skip-hooks` is the minimal opt-out.

### D4. Keep lefthook, don't add beads to it

Beads sync is not needed for the local-multi-agent case (the shared Dolt server IS the sync). Adding `bd sync` to `lefthook.yaml` would couple two independent tools and cost lefthook hook budget on every commit. Explicit non-goal.

Cross-machine sync, when we add it later, will go through Claude Code hooks (`SessionStart` for pull, `SessionEnd` for push, async, non-blocking) — same pattern as the existing `SessionStart` scratch-index hook in `modules/home-manager/ai/scratch.nix:37`. That's a separate change.

### D5. Package `beads-viewer` in the flake; drop `mardi-gras`

This change adds `inherit (llmAgentsPkgs) beads-viewer;` and removes the existing `mardi-gras` inherit. User has confirmed `bv` (beads-viewer) is the sole TUI going forward; `mg` is not needed. Both would have been fixed by the Rust→Go migration, but shipping only `bv` keeps the closure smaller and the UI surface smaller.

**Alternative considered:** keep both `bv` and `mg` for optionality. Rejected: user has made an explicit choice.

## Risks / Trade-offs

- **[Rust → Go data migration loses history if botched]** → Migration bead has an explicit verification gate: (1) `br export` to JSONL, (2) `mv .beads .beads.rust-backup`, (3) `bd init --skip-hooks`, (4) `bd import` (or scripted `bd create` loop), (5) diff issue count before/after, (6) only then run `bd close` on the migration bead. Do not proceed without human eyes on step 5.
- **[Whatever process currently spawns Dolt on this host might keep running after the swap]** → If the pre-existing dolt process is not owned by any nix module, `xi home switch` won't stop it. The managed `dolt-beads.service` will fail to bind port 32867 if the pre-existing process was already on that port. Mitigation: task 3.4 includes a pre-flight `lsof -i :32867` check and a documented manual `pkill dolt` if a stray instance is bound. Long-term: the follow-up change may need to remove whatever spawns the stray process.
- **[`GOMEMLIMIT` + `MemoryHigh` sizing miscalibration]** → Task 3.5 includes a manual load-test step (`bd create` in a loop while watching `systemd-cgtop`). Numbers are provisional until validated.
- **[dolthub/dolt#11526 connection slot leak still open]** → Mitigated but not fixed. Short `read_timeout_millis` + low `max_connections` + optional nightly restart timer (Task 7, optional) contain the blast radius. Revisit if upstream fixes.
- **[`bd import` may not exist or accept our JSONL format]** → Task 1.2 verifies before Task 6.5 runs. If import is not first-class, fall back to scripted `bd create` per JSONL line.
- **[Go bd's config schema for `hooks.enabled` may differ from what we're writing]** → Task 1.1 reads current Go bd source (`gastownhall/beads` docs/config) before generating the template. If the correct key is `no-git-ops: true` or `install-hooks: false`, we adapt.

## Migration Plan

**Order matters** — data migration happens per-repo *after* the derivation swap but *before* the user's next `bd` invocation in that repo, otherwise Go `bd` may create a fresh empty Dolt DB and mask the migration.

1. Land the flake changes (derivation swap, systemd unit, config file, gascity/beads-viewer packages, `.beads/config.yaml` template activation).
2. `xi home switch` — activates the new profile; `dolt-beads.service` starts.
3. Per repo with existing `.beads/beads.db` (Rust):
   a. `br export --format=jsonl > /tmp/beads-<repo-slug>-migration.jsonl` (or use the existing `.beads/beads.base.jsonl` if it's fresh)
   b. `mv .beads .beads.rust-backup-<YYYYMMDD>`
   c. `bd init --skip-hooks`
   d. `bd import /tmp/beads-<repo-slug>-migration.jsonl` (verify subcommand name first)
   e. Diff: `bd list --status=any | wc -l` vs the JSONL line count — must match within expected filter noise
   f. Only if diff is clean: leave `.beads.rust-backup-*` for one week, then delete
4. `lefthook install` in each affected repo (or let the existing lefthook-managed `.git/hooks/*` stand — they were never touched by the beads change).

**Rollback plan:**
- Revert the flake commit; `xi home switch` back to the previous generation.
- Per repo: `rm -rf .beads && mv .beads.rust-backup-<YYYYMMDD> .beads` restores the Rust-era database.
- `systemctl --user disable --now dolt-beads.service` (home-manager cleanup does this automatically on generation switch, but manual is safe).

## Open Questions

None that would change the specs, approach, or task breakdown. Two deferrable items are recorded as design decisions (D6 fallback) and risks (`bd import` verification), and are pursued inline as part of tasks — not blocked on user input.
