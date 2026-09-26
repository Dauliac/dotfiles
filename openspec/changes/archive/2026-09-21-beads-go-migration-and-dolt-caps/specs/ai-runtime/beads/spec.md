## Purpose

Defines the on-machine contract for the beads issue tracker as an AI-agent memory graph: which implementation is shipped, how the Dolt backend runs and is resource-capped, how multiple concurrent agents on the same host share bead state, how the tracker coexists with the repo's existing git-hook manager (lefthook), and which viewer is available. Owns the invariants that keep beads from burning CPU or clobbering the user's git hooks.

## ADDED Requirements

### Requirement: Implementation is the Go bd

The system SHALL expose the Go implementation of beads (gastownhall/beads, binary `bd`, Dolt-backed) as `pkgs.beads`. The system SHALL NOT ship the Rust reimplementation (`beads-rust`, binary `br`, SQLite-backed) as `pkgs.beads`.

#### Scenario: bd binary resolves to Go build
- **WHEN** any nix expression evaluates `${pkgs.beads}/bin/bd`
- **THEN** the resulting binary is the Go build from `llmAgentsPkgs.beads` (gastownhall/beads)
- **AND** `${pkgs.beads}/bin/bd --version` reports a version consistent with the pinned `llm-agents.nix` revision

#### Scenario: Rust binary is not shipped as beads
- **WHEN** any nix expression evaluates `${pkgs.beads}/bin/br`
- **THEN** the path does not exist

### Requirement: Dolt runs as a shared long-lived user service

The system SHALL run a single Dolt sql-server as a home-manager systemd user service (`systemd.user.services.dolt-beads`) that all concurrent beads clients on the machine connect to over TCP loopback. The system SHALL NOT rely on per-invocation embedded Dolt spawns for the primary beads workflow.

#### Scenario: Service is enabled at login
- **WHEN** the user logs in and the home-manager profile activates
- **THEN** `systemctl --user is-enabled dolt-beads.service` reports `enabled`
- **AND** `systemctl --user is-active dolt-beads.service` reports `active` within 10 seconds of login

#### Scenario: Multiple agents share the same server
- **WHEN** two or more processes on the same machine each invoke `bd` commands concurrently against the same `.beads/` database
- **THEN** all processes complete without database-lock errors
- **AND** each process observes the writes committed by the others (bounded by Dolt's MVCC visibility semantics)

#### Scenario: Service survives client crashes
- **WHEN** a `bd` client process is killed mid-connection
- **THEN** the sql-server continues running
- **AND** subsequent `bd` invocations from a fresh client connect successfully

### Requirement: Dolt service is CPU- and memory-capped

The `dolt-beads` systemd user service SHALL apply cgroup resource limits that prevent it from starving other processes on a laptop-class machine, and SHALL set Go runtime environment variables that prevent the idle-CPU regression documented in dolthub/dolt#10849.

#### Scenario: CPU quota is enforced
- **WHEN** the service is running
- **THEN** `systemctl --user show dolt-beads.service --property=CPUQuotaPerSecUSec` reports a value ≤ 500ms (i.e., ≤ 50% of one CPU)

#### Scenario: Memory soft limit is enforced
- **WHEN** the service is running
- **THEN** `systemctl --user show dolt-beads.service --property=MemoryHigh` reports a value ≤ 1 GiB
- **AND** `MemoryMax` reports a value ≤ 1.5 GiB
- **AND** `MemorySwapMax` reports 0
- **AND** `GOMEMLIMIT` (in the service environment) is set such that `GOMEMLIMIT < MemoryHigh` (Go GC fires before cgroup throttle)

#### Scenario: Go runtime env is set
- **WHEN** the service is running
- **THEN** the process environment includes `GOMEMLIMIT` set to a value ≤ 768 MiB
- **AND** the process environment includes `GOGC` set to a value ≥ 400

#### Scenario: Idle CPU stays low
- **WHEN** the service has been running for at least 60 seconds with no active bd client
- **THEN** the 60-second average CPU consumption of the dolt process stays below 5% of one core (soft target; verified manually with `top -p $(pgrep dolt)` or `systemctl status dolt-beads`)

### Requirement: Dolt config disables background workers unsuitable for low-QPS

The system SHALL ship a managed Dolt configuration at `~/.config/dolt-beads/config.yaml` that disables background workers not needed by a single-user beads workload, and applies short client timeouts that mitigate the connection-slot leak in dolthub/dolt#11526.

#### Scenario: Stats collector is off
- **WHEN** the sql-server is running with the managed config
- **THEN** `SELECT @@dolt_stats_enabled` returns `OFF` (or `0`)
- **AND** `SELECT @@dolt_stats_gc_enabled` returns `OFF` (or `0`)
- **AND** `SELECT @@dolt_stats_paused` returns `ON` (or `1`)

#### Scenario: Event scheduler is off
- **WHEN** the sql-server is running with the managed config
- **THEN** `SELECT @@event_scheduler` returns `OFF`

#### Scenario: Auto-GC is on
- **WHEN** the sql-server is running with the managed config
- **THEN** `SELECT @@dolt_auto_gc_enabled` returns `ON` (or `1`)

#### Scenario: Read timeout is short
- **WHEN** the sql-server is running with the managed config
- **THEN** the effective `read_timeout_millis` on the TCP listener is ≤ 30000
- **AND** `max_connections` is ≤ 32

### Requirement: Beads does not install git hooks

The system SHALL configure every repo's beads instance so that `bd init` does not write to `.git/hooks/*`. The system SHALL NOT add `bd sync` or `bd dolt push/pull` invocations to `lefthook.yaml`.

#### Scenario: Fresh init does not clobber git hooks
- **WHEN** a user runs `bd init` in a repo governed by the managed beads configuration
- **THEN** no files under `.git/hooks/` are created or modified by beads
- **AND** `.beads/hooks/` remains empty or contains no beads-installed shims

#### Scenario: Existing lefthook shims are preserved
- **WHEN** a repo has `lefthook install` shims in `.git/hooks/*` and the user runs any `bd` command
- **THEN** the `.git/hooks/*` files are byte-identical before and after the command

#### Scenario: Lefthook does not carry a beads step
- **WHEN** `lefthook.yaml` is inspected
- **THEN** no command entry invokes `bd sync`, `bd dolt push`, `bd dolt pull`, or any other beads subcommand

### Requirement: Beads config enforces hooks-disabled declaratively

The system SHALL write a managed `.beads/config.yaml` (or equivalent nix-activation guard) that ensures a subsequent `bd init` from any tool cannot re-enable the hook installer.

#### Scenario: Config asserts hooks off
- **WHEN** a repo governed by the managed beads configuration is inspected
- **THEN** `.beads/config.yaml` (or the equivalent config surface exposed by Go bd) contains a directive that disables hook installation
- **AND** running `bd hooks status` reports hooks as disabled

### Requirement: beads-viewer TUI is available

The system SHALL ship the `bv` (beads-viewer) terminal UI, and it SHALL successfully read the shared Dolt-backed beads database written by the Go `bd`. The system SHALL NOT ship the `mg` (mardi-gras) TUI in this change.

#### Scenario: bv reads current beads state
- **WHEN** the user runs `bv` against a `.beads/` populated by the Go `bd`
- **THEN** `bv` opens without a schema-mismatch error
- **AND** `bv` displays at least the issues the user created via `bd create`

#### Scenario: mg binary is not present
- **WHEN** the user runs `command -v mg`
- **THEN** the command reports "not found" (exit non-zero) OR resolves to a binary that is not part of the flake's home-manager profile

### Requirement: Per-invocation bd cost is bounded

Because Go bd connects to the shared Dolt service instead of spawning an embedded engine, the wall-clock cost of a `bd` invocation SHALL be dominated by the query, not by Dolt startup.

#### Scenario: bd ready is fast
- **WHEN** the user runs `time bd ready` on a small `.beads/` (fewer than 1000 issues) with the `dolt-beads` service active
- **THEN** the reported real time is ≤ 500ms on a laptop-class machine (soft target for manual verification)
