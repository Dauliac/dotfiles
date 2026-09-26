## 1. Declarative foundation (pure nix, no rust yet)

- [ ] 1.1 Add `modules/dotfiles/profiles.nix` defining `dotfiles.profiles` as an `nlib`-typed `attrsOf submodule` with fields `kind` / `flakeAttr` / `description` / `hostnameAliases` / `comin` (optional sub-submodule `{ enabled : bool = false; remote : str = ""; branch : str = ""; }`); verify `nix eval .#dotfiles.profiles --json` prints a syntactically valid JSON object and `nix eval .#dotfiles.profiles.<any>.comin.enabled` returns `false` by default.
- [ ] 1.2 Populate `dotfiles.profiles` with entries for `spongebob` (`os`), `gary` (`os`), `dauliac` (`os`), `juliendauliac` (`home`), and `ML-PF603JJ8` (`system`, alias `ML-PF59GCGW`), all with `comin.enabled = false` for now; verify `nix eval .#dotfiles.profiles.ML-PF603JJ8.hostnameAliases --json` returns `["ML-PF59GCGW"]` and every profile's `comin.enabled` is `false`.
- [ ] 1.3 Add `modules/dotfiles/scopes/default.nix` defining the `dotfiles.scopes` option (nlib-typed `attrsOf submodule` with `description` / `paths` / `hosts` / `narrowsBuild`); verify `nix eval .#dotfiles.scopes --json` prints `{}` before scopes are declared.
- [ ] 1.4 Add per-scope files `modules/dotfiles/scopes/{desktop,ai,terminal,security}.nix`, each declaring a single `dotfiles.scopes.<name>` entry with realistic `paths`; verify each scope's `paths` resolves to at least one existing file on disk under the flake root.
- [ ] 1.5 Add `nix flake check` job for the new options and confirm it passes on a locally staged tree (per dendritic pattern, files must be `git add`ed first).

## 2. Rust crate scaffolding

- [ ] 2.1 Create the workspace at `pkgs/dot/{Cargo.toml,rust-toolchain.toml,src/}` with `clap` (derive), `serde`, `serde_json`, `anyhow`, `thiserror`, and a stub `main.rs` that prints `{"command":"noop","schema_version":1,"status":"ok","data":{}}` under `--json`; verify `cargo run -- noop --json` on a dev machine returns exit `0` and valid JSON.
- [ ] 2.2 Add the flake package derivation at `pkgs/dot/default.nix` using `crane`, wire it into `flake.nix` as `packages.<system>.dot` and `apps.<system>.dot`; verify `nix build .#dot` succeeds and `nix run .#dot -- noop --json` prints the same stub JSON.
- [ ] 2.3 Add `modules/home-manager/programs/dot.nix` that installs `packages.<system>.dot` for every hostname in `dotfiles.profiles`; verify a home-manager dry-build for one host references the derivation.

## 3. Core capability (host detection, config source, exit codes)

- [ ] 3.1 Implement flake-root resolution in exactly this order: walk up from `$PWD` for a `flake.nix` containing `dotfiles.profiles`; then `$DOT_FLAKE_ROOT` if set; then `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles`. `$HOME/ghq/...` MUST NOT be honored as a fallback. Verify unit tests: (a) nested tmpdir with a synthesized `flake.nix` at the top returns the top path; (b) `XDG_DATA_HOME=/tmp/xdg` with a valid clone at `/tmp/xdg/dotfiles` returns that path when `$PWD` is `/tmp` and `$DOT_FLAKE_ROOT` is unset; (c) with `XDG_DATA_HOME` unset it falls back to `$HOME/.local/share/dotfiles`.
- [ ] 3.2 Implement `NixEval` module that shells out `nix eval --json .#dotfiles.profiles` and `.#dotfiles.scopes` in parallel with a shared timeout; verify integration test against this repo returns the same shape as the schemas in the specs.
- [ ] 3.3 Implement `dot detect [--json]` reporting `hostname`, `os_family` (one of `nixos`/`debian`/`ubuntu`/`other` — never `macos`), `nix_available`, matched `profile`, and a `comin` object `{ enabled, remote, branch, last_seen }`; verify running it on the current host prints a `profile.kind` matching the expected value from `dotfiles.profiles` and that `data.os_family` is never the literal string `"macos"`.
- [ ] 3.4 Implement the deterministic exit-code map (0/2/3/4/5/6/7/10) in a single `ExitCode` enum; verify a unit test asserts every numeric variant matches the values enumerated in `specs/dot-cli/core/spec.md`.
- [ ] 3.5 Implement `dot status [--json]` reporting `flake_root`, `hostname`, `profile`, `scopes`, and `warnings[]` (with the `unstaged-nix-file` code from the scopes spec); verify running it on a working tree with a modified but unstaged `.nix` file inside a scope surfaces exactly one warning.
- [ ] 3.6 Implement `dot doctor [--json]` with checks `git-worktree`, `xi-on-path`, `nix-on-path`, `redeploy-present`, and `comin-configured` (informational — MUST NOT cause a non-zero exit even when `ok == false`); verify (a) tampering with `$PATH` to hide `nix` causes `data.checks[nix-on-path].ok == false` with the `./redeploy.sh` hint; (b) a comin-disabled profile yields `comin-configured.ok == false` with the local-apply hint AND `dot doctor` still exits `0`; (c) a comin-enabled profile yields `comin-configured.ok == true` with the push-to-deploy hint.
- [ ] 3.7 Add `dot --version [--json]` short-path that skips `nix eval`; verify it exits <50 ms on a warm system.

## 4. Deploy capability (patch/build/deploy/commit/push)

- [ ] 4.1 Implement `dot patch --scope <name> --file <relpath> --content @<file>|-`; verify (a) writing inside a scope succeeds and reports `wrote_bytes`; (b) writing outside any scope path exits `2` with `path-outside-scope`.
- [ ] 4.2 Implement `dot build [--scope <name>] [--dry-run]` invoking `nix build .#<profile.flakeAttr>`, with scope narrowing when `narrowsBuild == true`; verify `--dry-run` prints the exact argv under `data.plan[]` and spawns nothing.
- [ ] 4.3 Implement `dot deploy [--dry-run] [--force-local-apply]` dispatching to `xi home switch .` / `xi os switch .` / `xi system switch .` based on `profile.kind` when `profile.comin.enabled == false` (or when `--force-local-apply` overrides comin); verify per-kind integration tests (mocked child process) call the matching argv exactly.
- [ ] 4.3a Implement the comin-aware branch of `dot deploy`: when `profile.comin.enabled == true` and `--force-local-apply` is NOT set, print the exact stderr warning `comin is configured (<remote>/<branch>): the last `dot push` is the deploy; skipping local apply`, emit `data.skipped_reason == "comin-enabled"` and `data.would_have_run.argv == ["xi","<kind>","switch","."]` under `--json`, spawn no child process, and exit `0`. Verify a fake profile with `comin.enabled=true` triggers exactly this behavior.
- [ ] 4.3b Verify `dot deploy --force-local-apply --dry-run --json` on a comin-enabled host prints `data.plan[0].argv == ["xi","<kind>","switch","."]`, spawns no `xi` process, and exits `0`.
- [ ] 4.4 Implement `dot commit --type <t> --scope <s> --subject <text> [--body @<f>|-]` with the conventional-commit type allowlist and a scope check against `dotfiles.scopes`; verify (a) invalid type exits `2` with `invalid-commit-type`; (b) unknown scope exits `2` with `unknown-scope`; (c) happy path invokes `git commit` with the composed message.
- [ ] 4.5 Implement `dot push [--force] [--allow-dirty] [--yes-i-know]` refusing `--force` without `--yes-i-know` and refusing on a dirty tree without `--allow-dirty`; verify each guard trips its expected exit code and no `git push` process is spawned when guarded.
- [ ] 4.6 Wire stderr tail capture (last 40 lines) for downstream failures (`xi` -> exit 5, `git` -> exit 6); verify a synthetic failing xi mock surfaces its tail under `data.error.stderr_tail`.
- [ ] 4.7 Add an end-to-end integration test (nix-driven, in a sandbox) that runs the push-first flow `dot patch → dot build --dry-run → dot commit --dry-run → dot push --dry-run → dot deploy --dry-run` in that order and asserts each step's JSON is self-contained, exit codes chain deterministically, and the trailing `dot deploy` (a) invokes `xi <kind> switch .` on a comin-disabled fake profile and (b) emits `data.skipped_reason == "comin-enabled"` on a comin-enabled fake profile.

## 5. Bootstrap capability (install.sh + first-run converge)

- [ ] 5.1 Implement `dot bootstrap --apply [--dry-run]` that always runs `xi home switch .` regardless of host kind (per design decision 6); verify on a HM host it prints `data.command.argv == ["xi","home","switch","."]` under `--dry-run`.
- [ ] 5.2 Author `install.sh` at repo root, POSIX-`sh` compatible, with OS detection via `/etc/os-release`+`uname`; verify `shellcheck -s sh install.sh` passes with no findings.
- [ ] 5.3 Implement OS-family branching in `install.sh`: NixOS → skip the Lix-installer step; Debian/Ubuntu → invoke `NIX_INSTALLER_NO_CONFIRM=1 curl -sSf -L https://install.lix.systems/lix | sh -s -- install --no-confirm`, then `. /etc/profile.d/nix.sh`; Darwin → exit `7` with the "macOS is not a supported target" message from the bootstrap spec; other → exit `7` with the `ID`/`ID_LIKE` message; verify each branch is reachable via unit test (env stub of `/etc/os-release` + `uname -s`).
- [ ] 5.4 Implement idempotent clone into `${DOTFILES_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles}` (fresh clone / ff-only pull / refuse unrelated tree); MUST NOT clone into `$HOME/ghq/...`; verify all three states behave as specified via a scratch integration test, AND verify that with `XDG_DATA_HOME=/tmp/xdg` and `DOTFILES_ROOT` unset the clone lands at `/tmp/xdg/dotfiles`.
- [ ] 5.5 Implement the "print `resume: …` hint on any non-zero exit" trap in `install.sh`; verify killing the script mid-way with `kill -TERM` results in a stderr line matching `^resume: `.
- [ ] 5.6 End-to-end validation: on a throwaway Debian VM (or container), running `curl -fsSL <URL>/install.sh | sh` finishes with `dot` on PATH of a fresh login shell; capture the transcript as the bootstrap acceptance evidence.

## 6. Agent integration (SKILL.md + skill contract)

- [ ] 6.1 Write `modules/home-manager/ai/capability/skills/dot/SKILL.md` with front-matter describing when to trigger (phrases: `dot patch`, `dot deploy`, `dot build`, `dot commit`, `dot push`, `dot bootstrap`, `deploy dotfiles`) and declaring `min_schema_version: 1`; verify the front-matter parses under the existing `capability/skills.nix` mechanism.
- [ ] 6.2 Document in `SKILL.md` the dot-vs-xi-vs-redeploy decision list from the agent-integration spec (Requirement 2) AND the push-first flow order `edit → build → commit → push → deploy?` from the deploy spec's "end-to-end AI-driven flow" requirement; verify a peer review of the skill against `specs/dot-cli/agent-integration/spec.md` and `specs/dot-cli/deploy/spec.md` passes.
- [ ] 6.3 Document in `SKILL.md` the destructive-command guardrails (Requirement 5): never call `dot push --force`, `--allow-dirty`, `--yes-i-know`, or `dot deploy --force-local-apply` without explicit user confirmation in the same turn.
- [ ] 6.4 Add a `dot --version --json` schema-check block to the skill that instructs the agent to abort if the binary reports a lower `schema_version` than `min_schema_version`.
- [ ] 6.5 Verify installation: run `xi home switch .` on `juliendauliac` and confirm `~/.claude/skills/dot/SKILL.md` exists byte-for-byte matching the source.

## 7. Break-glass compatibility

- [ ] 7.1 Update `redeploy.sh` docs (top-of-file comment only, not logic) to reference `dot doctor`; verify a `grep 'dot doctor' redeploy.sh` succeeds after the edit.
- [ ] 7.2 Confirm `dot doctor` output on a host with `nix` hidden from `$PATH` names `./redeploy.sh` verbatim in the hint; verify by running `PATH=/usr/bin dot doctor --json | jq '.data.checks[] | select(.name=="nix-on-path").hint'`.

## 8. Beads decomposition + change validation

- [ ] 8.1 Run `openspec validate add-dot-cli --strict` and address every finding; verify it exits `0`.
- [ ] 8.2 Run `beads-plan plan openspec/changes/add-dot-cli` to decompose this task list into a bead DAG; verify `bd ready` shows at least the top-of-tier tasks unblocked.
- [ ] 8.3 For every bead created in 8.2 whose source is this change, add `openspec: openspec/changes/add-dot-cli/design.md` in the description so the trail survives (per project CLAUDE.md).
- [ ] 8.4 Stop here — do NOT run `/opsx:apply`. Execution proceeds under beads from this point forward.
