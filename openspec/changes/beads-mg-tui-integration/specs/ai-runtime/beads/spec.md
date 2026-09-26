## MODIFIED Requirements

### Requirement: beads-viewer TUI is available

The system SHALL ship the `bv` (beads-viewer) terminal UI AND the `mg` (mardi-gras) terminal UI. Both SHALL successfully surface the current beads state — `bv` by reading the shared Dolt-backed beads database written by the Go `bd`, and `mg` by reading the passive JSONL export at `.beads/issues.jsonl`. Neither is a substitute for the other: they serve complementary views (`bv` is graph-aware; `mg` is a parade-timeline view).

#### Scenario: bv reads current beads state
- **WHEN** the user runs `bv` against a `.beads/` populated by the Go `bd`
- **THEN** `bv` opens without a schema-mismatch error
- **AND** `bv` displays at least the issues the user created via `bd create`

#### Scenario: mg reads current beads state
- **WHEN** the user runs `mg` in a repo whose `.beads/issues.jsonl` was freshly written by `bd sync --flush-only`
- **THEN** `mg` opens without a schema-mismatch error
- **AND** `mg` displays at least the issues the user created via `bd create`

#### Scenario: mg binary is present
- **WHEN** the user runs `command -v mg`
- **THEN** the command resolves to a `mardi-gras-*/bin/mg` path inside the flake's home-manager profile

#### Scenario: mg binary is not present
- **WHEN** the user removes `mardi-gras` from `modules/home-manager/ai/packages.nix` and its `inherit (llmAgentsPkgs)` entry in `modules/packages/default.nix`, then activates a new home-manager generation
- **THEN** `command -v mg` reports "not found" — this scenario documents the rollback contract; the shipped state is the "mg binary is present" scenario above
