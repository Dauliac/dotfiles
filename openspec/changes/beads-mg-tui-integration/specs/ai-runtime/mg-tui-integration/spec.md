## Purpose

Defines when and how an AI agent auto-opens the `mg` (mardi-gras) TUI in a `herdr` split as a live side-panel view during beads workflows. Covers trigger conditions, split shape, label conventions, deduplication (don't spawn a duplicate when one already exists), flush-cadence coupling (so the JSONL `mg` reads stays current), and auto-close policy. Complements the pure "which TUI is shipped" contract in `ai-runtime/beads`.

## ADDED Requirements

### Requirement: An mg-watch skill exists and is discoverable via the skill-loader

The system SHALL ship an `mg-watch` skill at `modules/home-manager/ai/capability/skills/engineering/mg-watch/SKILL.md` and SHALL register it in the engineering skill list in `modules/home-manager/ai/capability/skills.nix` so home-manager materializes it under `~/.claude/skills/mg-watch/`. The skill's YAML frontmatter description SHALL list trigger phrases sufficient for the mandatory word-match self-check to fire it whenever beads work begins.

#### Scenario: skill materialized under the Claude skills directory
- **WHEN** the home-manager profile is activated
- **THEN** `~/.claude/skills/mg-watch/SKILL.md` exists
- **AND** it is a symlink (direct or via `home-manager-files`) rooted at `modules/home-manager/ai/capability/skills/engineering/mg-watch/SKILL.md` in this repo

#### Scenario: skill description contains beads-workflow trigger phrases
- **WHEN** the SKILL.md frontmatter is inspected
- **THEN** the `description:` field contains at least the phrases `bd ready`, `bd claim`, `beads workflow`, and one variant of "open mg" / "mg split" / "side-panel"
- **AND** the total description length stays under 500 characters (keeps metadata cost bounded per the skill-loader budget)

### Requirement: mg-watch spawns a single herdr-tui split

When triggered, the `mg-watch` skill SHALL invoke `herdr-tui launch` with an `mg-<repo-slug>` label, arm `--auto-close-on-idle 900` (15 minutes; a live task panel gets glanced at many times per session, so a shorter idle window would prematurely close it), and prefix the `mg` invocation with `bd sync --flush-only` so the JSONL export is fresh before `mg` opens it.

#### Scenario: label follows the mg-<repo-slug> convention
- **WHEN** `mg-watch` fires in a repo whose basename is `<name>`
- **THEN** the `herdr-tui launch --label` argument is `mg-<name>` (kebab-case, lowercased)

#### Scenario: flush precedes launch
- **WHEN** `mg-watch` fires
- **THEN** the command passed to `herdr-tui launch --` starts with `bd sync --flush-only &&` (or an equivalent shell sequence) before invoking `mg`, so `mg` reads a JSONL that reflects every bd write up to that instant

#### Scenario: default auto-close policy is 15-minute idle
- **WHEN** `mg-watch` fires without an explicit auto-close override
- **THEN** the invocation carries `--auto-close-on-idle 900`
- **AND** it does NOT carry `--auto-close-when` (there is no useful "done" predicate for beads work)

### Requirement: mg-watch deduplicates against existing mg panes

The skill SHALL check for an existing `mg` split in the current herdr workspace (by label prefix `mg-`) before spawning a new one; if one exists, the skill SHALL NOT spawn a duplicate.

#### Scenario: existing mg split blocks a second spawn
- **WHEN** an `mg-<name>` labeled pane already exists in the current herdr workspace
- **AND** the agent evaluates whether to fire `mg-watch`
- **THEN** the skill emits no new `herdr-tui launch` call
- **AND** the skill reports (in agent-visible text) "mg already open in pane <label>"

### Requirement: beads and beads-flow skills cross-reference mg-watch

The `beads` and `beads-flow` skill descriptions SHALL each include a one-line pointer to `mg-watch` so the word-match self-check surfaces `mg-watch` alongside them.

#### Scenario: beads skill lists mg-watch under Composes with
- **WHEN** the `beads` SKILL.md file is inspected
- **THEN** the description (frontmatter) OR the body contains a phrase like "Pair with mg-watch for a live side-panel" or "Composes with: mg-watch"

#### Scenario: beads-flow skill lists mg-watch under Composes with
- **WHEN** the `beads-flow` SKILL.md file is inspected
- **THEN** the description (frontmatter) OR the body contains a phrase like "Pair with mg-watch for a live side-panel" or "Composes with: mg-watch"
