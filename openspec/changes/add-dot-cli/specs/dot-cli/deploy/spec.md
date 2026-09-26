## Purpose

Defines the `dot patch`, `dot build`, `dot commit`, `dot push`, and `dot deploy` subcommands — the operational surface an AI agent uses to move the repo through the flow `edit → build → commit → push → (local-apply, only if comin is not configured)`. Every subcommand SHALL wrap `xi` and `git` rather than re-implement them, and `dot deploy` is comin-aware: on a host with comin enabled, `dot push` is the deploy trigger and `dot deploy` no-ops with a warning unless `--force-local-apply` is passed.

## ADDED Requirements

### Requirement: dot patch edits a single module under a scope

`dot patch --scope <name> --file <relpath> --content @<file>` (or `--content -` for stdin) SHALL write the given content atomically to `<flake_root>/<relpath>` after validating that `<relpath>` is inside one of `dotfiles.scopes.<name>.paths`. It MUST NOT touch files outside the scope. It MUST NOT auto-stage the file (see `scopes` spec, `unstaged-nix-file` warning).

#### Scenario: writing inside a scope

- **WHEN** the user runs `dot patch --scope ai --file modules/home-manager/ai/capability/skills/dot/SKILL.md --content @/tmp/new.md`
- **THEN** the file is written atomically and stdout (under `--json`) reports `data.wrote_bytes` and `data.scope == "ai"`

#### Scenario: writing outside any scope

- **WHEN** the user attempts `dot patch --scope ai --file docs/random.md ...` and `docs/` is not in `dotfiles.scopes.ai.paths`
- **THEN** `dot patch` exits `2` with `data.error.code == "path-outside-scope"` and the file is not written

### Requirement: dot build wraps nix build for the current profile

`dot build [--scope <name>]` SHALL invoke `nix build .#<profile.flakeAttr>` (without `--scope`) or a scope-narrowed derivation when `dotfiles.scopes.<name>.narrowsBuild == true`. When `narrowsBuild == false`, `dot build --scope <name>` MUST print (and, under `--json`, set `data.narrowed == false`) but proceed with the full build so behavior remains predictable.

#### Scenario: full build for detected profile

- **WHEN** `dot build --json` runs on `juliendauliac`
- **THEN** `data.command.argv[0] == "nix"` and `data.command.argv[1] == "build"` and `data.command.argv` contains `.#homeConfigurations.juliendauliac`

#### Scenario: narrowable scope

- **WHEN** `dot build --scope terminal --json` runs and `dotfiles.scopes.terminal.narrowsBuild == true`
- **THEN** `data.narrowed == true` and the derivation actually built is a subset defined by the scope

### Requirement: dot deploy dispatches to the correct xi subcommand

`dot deploy` SHALL, when it decides to run a local apply, dispatch to exactly one of:

- `xi home switch .` when `profile.kind == "home"`
- `xi os switch .` when `profile.kind == "os"`
- `xi system switch .` when `profile.kind == "system"`

`dot deploy` MUST NOT introduce a fourth kind, MUST NOT invoke `nixos-rebuild`/`home-manager`/`system-manager` directly, and MUST NOT swallow or rewrite xi's stderr — only mirror it and, under `--json`, capture its tail. Whether it runs any of the above at all is governed by the next requirement (comin awareness).

#### Scenario: NixOS host, comin disabled

- **WHEN** `dot deploy` runs on `spongebob` with `profile.comin.enabled == false`
- **THEN** the child process argv equals `["xi", "os", "switch", "."]`

#### Scenario: system-manager host, comin disabled

- **WHEN** `dot deploy` runs on `ML-PF603JJ8` (or its alias `ML-PF59GCGW`) with `profile.comin.enabled == false`
- **THEN** the child process argv equals `["xi", "system", "switch", "."]`

#### Scenario: home-manager host, comin disabled

- **WHEN** `dot deploy` runs on `juliendauliac` with `profile.comin.enabled == false`
- **THEN** the child process argv equals `["xi", "home", "switch", "."]`

### Requirement: dot deploy is comin-aware

When the current profile's `comin.enabled == true`, `dot deploy` SHALL by default NOT invoke `xi ... switch .` — instead it MUST print a stderr warning of the form `comin is configured (<remote>/<branch>): the last `dot push` is the deploy; skipping local apply`, MUST report `data.skipped_reason == "comin-enabled"` under `--json`, and MUST exit `0`. Passing `--force-local-apply` overrides this and runs the same `xi ... switch .` as the comin-disabled path. `--force-local-apply` is INCOMPATIBLE with `--dry-run` in the sense that the two together SHALL print the argv that WOULD run and still exit `0` without spawning `xi`.

#### Scenario: comin-enabled host, default deploy

- **WHEN** `dot deploy --json` runs on a host with `profile.comin = { enabled = true; remote = "origin"; branch = "main"; }`
- **THEN** stdout is a JSON document with `status == "ok"`, `data.skipped_reason == "comin-enabled"`, `data.would_have_run.argv == ["xi", "<kind>", "switch", "."]`, and no `xi` process is spawned

#### Scenario: comin-enabled host, forced local apply

- **WHEN** `dot deploy --force-local-apply --json` runs on the same host as above
- **THEN** `xi ... switch .` is spawned exactly as if comin were disabled, and `data.skipped_reason` is absent

#### Scenario: comin-enabled host, forced apply plus dry-run

- **WHEN** `dot deploy --force-local-apply --dry-run --json` runs on the same host
- **THEN** `data.plan[0].argv == ["xi", "<kind>", "switch", "."]`, no `xi` process is spawned, and the exit code is `0`

### Requirement: dot commit uses conventional commit style

`dot commit --type <type> --scope <scope-name> --subject <text> [--body @<file>|-]` SHALL run `git commit` with a message body of the form `<type>(<scope>): <subject>\n\n<body>`. `<type>` MUST be one of `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `build`, `ci`, `perf`, `style`, `revert`. `<scope>` MUST be a key of `dotfiles.scopes`. `dot commit` MUST NOT `git add` files itself — the caller (agent or human) stages first.

#### Scenario: happy-path commit

- **WHEN** the user runs `dot commit --type feat --scope ai --subject "add dot skill" --body -` with body on stdin
- **THEN** `git commit` is invoked with exactly that message, and exit code `0` is returned iff git returns `0`

#### Scenario: invalid conventional-commit type

- **WHEN** the user runs `dot commit --type feat! ...`
- **THEN** `dot commit` exits `2` with `data.error.code == "invalid-commit-type"` and no `git` process is spawned

#### Scenario: scope not registered

- **WHEN** the user runs `dot commit --type feat --scope observability ...` and `dotfiles.scopes.observability` is not defined
- **THEN** `dot commit` exits `2` with `data.error.code == "unknown-scope"`

### Requirement: dot push refuses force-push by default

`dot push` SHALL invoke `git push` with the current branch's upstream and MUST reject `--force` or `--force-with-lease` unless the caller passed `--yes-i-know`. `dot push` MUST NOT push when `git status --porcelain` reports a non-empty working tree, unless `--allow-dirty` is set.

#### Scenario: clean tree, fast-forward push

- **WHEN** the working tree is clean and the local branch is ahead of upstream by pushable commits
- **THEN** `dot push` runs `git push` and exits `0` on success

#### Scenario: force-push without the guard flag

- **WHEN** the user runs `dot push --force`
- **THEN** `dot push` exits `2` with `data.error.code == "force-requires-yes-i-know"`

### Requirement: end-to-end AI-driven flow is push-first, apply-conditional

The prescribed sequence SHALL be `dot patch … && dot build && git add … && dot commit … && dot push && dot deploy` — build gates commit, commit gates push, and `dot deploy` runs LAST. When the current profile's `comin.enabled == true`, `dot deploy` in that trailing position is a no-op-with-warning (see previous requirement) because the push already triggered comin; when `comin.enabled == false`, `dot deploy` performs the local `xi ... switch .`. Each step MUST be independently retryable (idempotent within a single logical change) and each MUST honor `--json` and the exit-code table defined in the `core` capability.

#### Scenario: agent-driven change on a comin-disabled host

- **WHEN** an AI agent runs the six-step sequence with `--json` on each command on a host with `comin.enabled == false`
- **THEN** the final `dot deploy` invokes `xi ... switch .`, each stdout is a self-contained JSON document, and any failure surfaces as a specific exit code from the `core` spec's table

#### Scenario: agent-driven change on a comin-enabled host

- **WHEN** an AI agent runs the same sequence on a host with `comin.enabled == true`
- **THEN** `dot push` completes normally, the final `dot deploy` exits `0` with `data.skipped_reason == "comin-enabled"`, and no local `xi ... switch .` is spawned
