## 1. Upstream research (no code)

- [ ] 1.1 Confirm Go bd's config-file schema: which top-level key disables hook installation (`hooks.enabled: false`, `no-git-ops: true`, `install-hooks: false`, other). Read `gastownhall/beads` `docs/reference/configuration.md` and `pkg/config/*.go` if needed. Verification: paste the exact YAML key + accepted values into an update to `design.md#D3`.
- [ ] 1.2 Confirm Go bd's JSONL import subcommand: `bd import`, `bd sync --import`, `bd load`, or none. Verification: run `${pkgs.beads}/bin/bd help | grep -Ei 'import|load'` after task 2.1 lands; document exact command in `design.md#Migration Plan step 3d`.
- [ ] 1.3 Verify `${pkgs.beads}/bin/bd agents --add --dry-run` still works with the Go CLI. Verification: run against a scratch dir after task 2.1 lands; if the subcommand differs, note the new form so task 5.2 can adapt `modules/home-manager/ai/workspace/rules.nix`.

## 2. Package swap (flake / nix)

- [ ] 2.1 Edit `modules/packages/default.nix` — remove the `beads = symlinkJoin { paths = [ beads-rust ]; ... }` block; replace with `inherit (llmAgentsPkgs) beads beads-viewer;`. Remove the `mardi-gras` inherit line. Drop the `br → bd` symlink and the `beads-rust` reference entirely. Verification: `nix flake check` passes; `nix eval .#legacyPackages.x86_64-linux.beads.meta.mainProgram` returns `"bd"` (not `"br"`); `nix eval .#legacyPackages.x86_64-linux.beads-viewer.meta.mainProgram` returns `"bv"`.
- [ ] 2.2 Update `modules/home-manager/ai/packages.nix` to add `beads-viewer` and remove `mardi-gras` from the AI package list. Verification: `home-manager packages | grep -E '^(beads|beads-viewer)-'` lists both; `home-manager packages | grep -E '^mardi-gras-'` returns empty.
- [ ] 2.3 Grep the repo for any lingering `beads-rust`, `${pkgs.beads}/bin/br`, or `mardi-gras` references and delete: `grep -rn 'beads-rust\|/bin/br\b\|mardi-gras' modules/ .agents/ .claude/`. Verification: grep returns empty; `nix flake check` still passes.

## 3. Dolt sql-server systemd user service

- [ ] 3.1 Create `modules/home-manager/services/dolt-beads.nix` defining `systemd.user.services.dolt-beads` per `design.md#D2` (Type=simple, ExecStart calls `${pkgs.dolt}/bin/dolt sql-server --config %h/.config/dolt-beads/config.yaml`, Restart=on-failure, KillSignal=SIGTERM, TimeoutStopSec=30s, cgroup limits, Environment=GOGC=400 GOMEMLIMIT=768MiB, hardening: ProtectSystem=strict / ProtectHome=read-only / ReadWritePaths=[%h/.local/share/dolt-beads %h/.config/dolt-beads]). Verification: after `xi home switch`, `systemctl --user is-enabled dolt-beads.service` = enabled; `systemctl --user status dolt-beads.service` shows Active: active (running).
- [ ] 3.2 In the same file, generate `xdg.configFile."dolt-beads/config.yaml"` from the YAML in `design.md#D2` + `specs/ai-runtime/beads/spec.md#Requirement: Dolt config disables background workers`. Include `data_dir: %h/.local/share/dolt-beads`, `listener.host=127.0.0.1 port=32867 max_connections=8 back_log=4 read_timeout_millis=30000 write_timeout_millis=30000`, `behavior.auto_gc_behavior.{enable=true, archive_level=1}`, `system_variables.{dolt_stats_enabled=OFF, dolt_stats_gc_enabled=OFF, dolt_stats_memory_only=ON, dolt_stats_paused=ON, event_scheduler=OFF, wait_timeout=30}`. Verification: after `xi home switch`, `dolt sql-client --host=127.0.0.1 --port=32867 --user=root -e 'SELECT @@dolt_stats_enabled, @@event_scheduler, @@dolt_auto_gc_enabled'` returns `OFF, OFF, ON` (values may be 0/OFF, 1/ON depending on Dolt version — accept either form).
- [ ] 3.3 Create `~/.local/share/dolt-beads/` on first activation via `home.activation.doltBeadsDataDir` running `mkdir -p ~/.local/share/dolt-beads`. Verification: after `xi home switch` on a fresh state, the directory exists with mode 0700.
- [ ] 3.4 Import the new service module into the user's home-manager config (`modules/home.juliendauliac/default.nix` — mirror how other `services/*.nix` modules are imported, if any; otherwise via `imports = [ ./services/dolt-beads.nix ]` in a suitable barrel). BEFORE first `xi home switch`, run `lsof -i :32867` to catch any pre-existing dolt process bound to the target port; if present, kill it manually (`pkill dolt`) and re-check. Verification: `systemctl --user list-unit-files dolt-beads.service` shows the unit; `systemctl --user status dolt-beads.service` reports active; `ss -tlnp 'sport = :32867'` shows only the managed dolt process.
- [ ] 3.5 Load-test cgroup sizing: with the service active, run `for i in $(seq 1 100); do bd create --title "test $i" --priority 3; done` in a scratch beads repo while `systemd-cgtop` is open in a herdr split. Confirm memory RSS stays under `MemoryHigh`; if it exceeds, adjust `GOMEMLIMIT` and `MemoryHigh` per `design.md#Risks/Trade-offs` and commit the corrected numbers. Verification: recorded RSS peak from `systemd-cgtop` in a `bd note` on the corresponding bead, showing peak < `MemoryHigh`.

## 4. Managed .beads/config.yaml + hook-clobber guard

- [ ] 4.1 Create `modules/home-manager/ai/beads-config.nix` defining a `home.activation.beadsRepoConfig` script (or a `home.file`-based template — pick whichever fits the pattern of existing modules) that, for each git repo the user opens containing a `.beads/` directory, ensures `.beads/config.yaml` contains the hooks-disabled directive from task 1.1. Do NOT run `bd init` automatically. Verification: create a scratch repo, `bd init` (should install hooks), then trigger the activation, confirm hooks are re-disabled and `.beads/config.yaml` has the correct directive.
- [ ] 4.2 Add a `SessionStart` claude-code hook (following the pattern in `modules/home-manager/ai/scratch.nix:37`) that runs `bd hooks status` in the current repo and re-disables hooks if they've been re-enabled. Marker: `async = true`, `timeout = 5`. Verification: manually run `bd hooks install` in a scratch repo, then start a new claude session in that dir, confirm hooks are disabled by session start.
- [ ] 4.3 Verify `lefthook.yaml` still has no beads-related commands. Verification: `grep -Ei 'beads|bd ' lefthook.yaml` returns empty.

## 5. Adapt existing callsites

- [ ] 5.1 Remove the `mg` alias from `modules/home-manager/aliases.nix`. Optionally add a `bv` alias pointing at `${pkgs.beads-viewer}/bin/bv`. Verification: `grep -E '"mg"\s*=' modules/home-manager/aliases.nix` returns empty; `zsh -ic 'type bv'` (if alias added) shows the alias.
- [ ] 5.2 Update the `bd agents --add --dry-run` invocation in `modules/home-manager/ai/workspace/rules.nix` if task 1.3 revealed the Go CLI differs. Verification: `nix build .#legacyPackages.x86_64-linux.<the-rules-derivation>` succeeds and produces a non-empty rules file.
- [ ] 5.3 Verify remaining `${pkgs.beads}/bin/bd` callsites still resolve after task 2.1. Verification: `nix build .#homeConfigurations.juliendauliac.activation-script` succeeds.

## 6. Data migration (per repo, manual)

- [ ] 6.1 Baseline: run `br list --status=any --format=jsonl 2>/dev/null || cat .beads/beads.base.jsonl | wc -l` for each repo listed by `find ~/ghq -type d -name '.beads' 2>/dev/null` and record the count in a bead. Verification: bead note has one line per repo: `<path>: <count>`.
- [ ] 6.2 For each repo with `.beads/beads.db`: `br export --format=jsonl > /tmp/beads-<slug>-migration.jsonl`. Verification: file exists, is non-empty, first + last line parse as JSON via `head -1 /tmp/beads-<slug>-migration.jsonl | jq .`.
- [ ] 6.3 Move the Rust `.beads/` aside: `mv .beads .beads.rust-backup-$(date +%Y%m%d)`. Verification: `test ! -d .beads && test -d .beads.rust-backup-*`.
- [ ] 6.4 Initialize the Go `.beads/`: `bd init --skip-hooks`. Verification: `test -d .beads/embeddeddolt` (or whatever the Go layout uses per task 1.1) AND `.git/hooks/` unchanged (byte-identical to before task 6.3).
- [ ] 6.5 Import the JSONL: `bd import /tmp/beads-<slug>-migration.jsonl` (exact command per task 1.2). Verification: `bd list --status=any | wc -l` matches the count from task 6.1 within ± issues that were `deleted`/`archived` in the Rust DB (document the delta in a bead note).
- [ ] 6.6 Retention: leave `.beads.rust-backup-*` for at least 7 days before deleting. Verification: bead note with cleanup date.

## 7. Optional hardening

- [ ] 7.1 (Optional) Add a `systemd.user.timers.dolt-beads-restart` that fires nightly and does `systemctl --user restart dolt-beads.service` — cheap workaround for dolthub/dolt#11526 connection-slot leak. Verification: `systemctl --user list-timers dolt-beads-restart` lists it with a Next: field.
- [ ] 7.2 (Optional) Package a small `/beads-sync` slash command in `.claude/commands/` for manual "push state now" if/when we add cross-machine sync in a follow-up change. Skip for this change unless follow-up starts.

## 8. Validation

- [ ] 8.1 Run `openspec validate beads-go-migration-and-dolt-caps --strict` and address any warnings. Verification: exit 0.
- [ ] 8.2 Regression: `bv` opens without a schema error against a real (post-migration) `.beads/`. Verification: `bv` launches, shows at least one issue, `q` exits cleanly.
- [ ] 8.3 Idle CPU acceptance: with no active `bd` client for 60s, `top -bn1 -p $(pgrep dolt) | tail -2` shows < 5% CPU for the dolt process. Verification: recorded in a bead note.
- [ ] 8.4 Multi-agent smoke test: in two separate shells, `bd create --title 'shell1 $(date)'` and `bd create --title 'shell2 $(date)'` concurrently; `bd list` from a third shell shows both. Verification: exit 0 from all three commands, both issues visible.
- [ ] 8.5 Hook-non-clobber acceptance: after everything is deployed, `stat -c '%Y' .git/hooks/pre-commit` before and after running any `bd` command shows identical mtimes. Verification: `stat` timestamps match exactly.
