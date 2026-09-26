## Context

See proposal.md ("Why") for motivation. Design-level context that shapes the approach:

- The flake already uses **flake-parts + import-tree** (dendritic pattern). Any new module must be a self-contained `flake-parts` module discovered via import-tree, and must be **git-staged** to be visible.
- `nlib` (github:Dauliac/nlib) is the option-builder framework used across the repo — it wraps flake-parts via `nlib.lib.mkFlake`. New option namespaces (`dotfiles.profiles`, `dotfiles.scopes`) must use nlib combinators, not raw `lib.types`.
- `xi` (github:Dauliac/xi) is the nix CLI in use — `xi home switch .`, `xi os switch .`, `xi system switch .`. It replaces `nh` and bundles a nix-lib adapter; there is a known infinite-recursion interaction with nixvim (documented in MEMORY.md; not a blocker for this change because `dot` doesn't touch that path).
- Hosts today: NixOS `spongebob`, `gary`; NixOS + HM `dauliac`; HM-standalone (non-NixOS Debian) `juliendauliac`; system-manager host `ML-PF603JJ8` (predecessor `ML-PF59GCGW` still has a module but is unused). All targeted hosts are Linux — Debian or NixOS. There is no darwin host and macOS is not a supported bootstrap target.
- Break-glass path exists: `redeploy.sh` at repo root sources `/etc/profile.d/nix.sh` then runs `xi system switch .`. This must not go away — `dot doctor` points at it when nix is off `PATH`.
- **XDG-native layout**: the dotfiles working tree lives under `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles`, not `$HOME/ghq/...`. Dotfiles are data (a git working tree), not config, so `$XDG_DATA_HOME` is the correct base. The `install.sh` clone target and `dot`'s fallback flake-root discovery both agree on this path, so a fresh clone is immediately findable by the freshly-installed binary without any env-var handoff.
- **comin push-to-deploy**: [comin](https://github.com/nlewo/comin) is a NixOS/HM GitOps daemon that polls a git remote and applies on new commits. Any host in `dotfiles.profiles` can opt into it via a per-profile `comin` sub-submodule. When enabled, `dot push` is the deploy trigger and `dot deploy` no-ops with a warning. When disabled, `dot deploy` performs the local `xi ... switch .` after `dot push`. This is why the E2E flow is push-first, apply-conditional (`edit → build → commit → push → deploy?`), not deploy-then-push as the earlier draft implied.
- OpenSpec is the design layer; **beads** owns per-task execution (per project CLAUDE.md). `tasks.md` here is the seed for `beads-plan plan openspec/changes/add-dot-cli`.

## Goals / Non-Goals

**Goals:**

- Ship a single Rust binary `dot` that reads its config exclusively from `nix eval --json` (declarative-or-nothing).
- Provide a stable JSON contract (`schema_version: 1`) and deterministic exit codes for AI-agent-driven workflows.
- Provide a `curl … | sh` bootstrap that works on NixOS and non-NixOS (Debian/Ubuntu/macOS).
- Keep `xi` as the sole nix-side deploy engine; `dot deploy` is a dispatcher, not a re-implementation.
- Ship a Claude skill co-located with the flake so an agent invoked anywhere in the laptop can drive `dot`.
- Package `dot` as a flake output (`packages.<system>.dot` + `apps.<system>.dot`) so `nix run` works before any install.

**Non-Goals:**

- Not replacing `xi`. `dot` does not know how to build NixOS/HM/system-manager configurations itself.
- Not replacing `redeploy.sh`. It stays as the break-glass. `dot doctor` merely points at it.
- Not a general-purpose git/GitHub CLI. `dot commit` is conventional-commit-only; `dot push` refuses force by default. Anything richer (PRs, reviews) stays with `gh`/`glab`.
- Not a daemon / TUI. `dot` is one-shot, exits when done, has no state on disk (config is nix-eval'd every call).
- Not a config-file-driven tool. **No** TOML/YAML/JSON config file under `$XDG_CONFIG_HOME/dot/` or colocated with the binary.
- Not a "manage other dotfiles repos" tool. This dotfiles repo is the only supported flake.
- Windows is out of scope.

## Decisions

### Decision 1 — Rust build wrapping: `crane` over `rustPlatform.buildRustPackage`

**Choice:** use `crane` (github:ipetkov/crane) for the `pkgs/dot` derivation.

**Rationale:** `crane` gives incremental caching of `cargo` deps as a separate FOD, which pays off every time an agent rebuilds `dot` mid-session. `rustPlatform.buildRustPackage` recompiles all deps on any change. The repo already uses composed flake inputs; adding `crane` as an input is a one-line cost.

**Alternatives considered:**

- `rustPlatform.buildRustPackage`: simplest but slowest for iterative dev. Rejected.
- `naersk`: functionally similar to `crane` but less actively maintained. Rejected.
- Cargo-only outside nix: violates "declarative-or-nothing" — `dot` itself must be installable via home-manager.

### Decision 2 — Bootstrap installer: Lix installer

**Choice:** `install.sh` invokes `NIX_INSTALLER_NO_CONFIRM=1 curl -sSf -L https://install.lix.systems/lix | sh -s -- install --no-confirm` on Debian/Ubuntu. On NixOS the step is skipped entirely (nix is provided by the system).

**Rationale:** the user runs Lix, not upstream Nix. The Lix installer is a customised fork of the Determinate installer (per its own `install.lix.systems/lix` shell script header), so it inherits Determinate's cross-distro reliability (atomic uninstaller, systemd handling, rootless variants) while producing a `lix`-branded evaluator that matches the daily driver. Passing both `--no-confirm` AND exporting `NIX_INSTALLER_NO_CONFIRM=1` is belt-and-suspenders: the upstream script's line-123 check refuses to run when stdin is not a TTY unless one of those two signals is present, and `curl | sh` invocation always has stdin bound to the script — the env var is the more robust of the two, the flag is documented.

**Alternatives considered:**

- Determinate Nix installer (previous draft): produces an upstream-Nix evaluator, not Lix; mismatch with the user's chosen daily driver.
- Official `install.sh` from nixos.org: less robust on Debian/Ubuntu, no built-in uninstall.
- Package-manager install (`apt-get install nix`): stale, wrong version, and can't be Lix.
- Pin a specific `lix-installer` binary from `git.lix.systems/lix-project/lix-installer/releases` and re-serve it ourselves: brittle (version drift, mirror maintenance) and hides the upstream-signed provenance we get by piping the canonical URL. Reject unless upstream availability becomes a real problem.

### Decision 3 — Config source: `nix eval --json` on every invocation, no cache

**Choice:** every `dot` invocation shells out `nix eval --json .#dotfiles.profiles` and `nix eval --json .#dotfiles.scopes` (in parallel), parses the JSON, and holds it in memory for the lifetime of that process.

**Rationale:** matches the "declarative-or-nothing" mandate. `nix eval` is fast on a warm store (<200 ms typical) and gives us a single source of truth. Caching to disk would risk staleness after the user adds a scope; agents would then chase phantom scopes. If perf becomes an issue, add an in-process cache — never an on-disk one.

**Alternatives considered:**

- Codegen a Rust module from the nix eval at build time: fast, but requires rebuilding `dot` on every scope/profile change — kills the "no rebuild for config" requirement (`scopes` spec).
- Read a TOML/YAML file: violates "declarative-or-nothing".
- Ship a long-running daemon that watches the flake: adds a whole failure surface (dbus, restart-on-crash) for a tool that runs a few times an hour.

### Decision 4 — Profile detection: `hostnamectl` + aliases in the nix module

**Choice:** detection is `hostnamectl hostname` first (falls back to `hostname` then to `/etc/hostname`). The `nlib`-defined submodule for each profile includes `hostnameAliases` so that renamed machines (the `ML-PF603JJ8` / `ML-PF59GCGW` case in MEMORY.md) map to the same profile without duplication.

**Rationale:** hostname is the least-worst identity signal on multi-OS laptops. `hostnamectl` is preferred because it's what `system-manager` itself uses (the MEMORY.md note explicitly warns against trusting older hostname sources). Aliases live in nix, where the mapping is auditable, rather than in a rust map.

**Alternatives considered:**

- Machine-id: stable but opaque and painful to declare in nix without leaking secrets.
- MAC address: unstable across VPN / dock / hotspot switches.
- Prompt the user: unusable in agent-driven `--json` flows.

### Decision 5 — CLI framing: `clap` derive API + `serde` for JSON

**Choice:** `clap` with the derive API (subcommand-per-enum-variant), `serde`/`serde_json` for the `--json` contract, `anyhow` at the CLI boundary + `thiserror` for typed errors inside library modules.

**Rationale:** stable ecosystem, cheap to compile, plays well with `crane` caching. Derive API keeps the `Cli` struct as the readable spec of the surface. `anyhow` at the boundary lets us map any error into the deterministic exit-code table from the `core` spec without ceremony inside subcommand code.

**Alternatives considered:**

- `argh`: smaller but no `--json`-friendly derive story; not worth the migration risk.
- Rolling our own parser: no.

### Decision 6 — `dot bootstrap --apply` runs `xi home switch .` (never `os` or `system`) on first run

**Choice:** the initial converge from `install.sh` is always `xi home switch .` — the home-manager path — regardless of host. NixOS/system-manager conversion happens on a *second*, human-approved deploy.

**Rationale:** `curl | sh` is untrusted-by-default: an installer that immediately rewrites `/etc/nixos/*` or system-manager state on a non-NixOS box is a footgun. Home-manager is per-user, reversible with a rollback, and produces `dot` on `PATH`. From there the user (or the agent, with explicit confirmation) can run `dot deploy` to trigger the profile-appropriate switch. The `SKILL.md` documents this two-step dance.

**Alternatives considered:**

- Detect and dispatch directly on first run: unsafe on non-NixOS where an `xi os switch` would be nonsense, and on NixOS it's a large blast-radius before the user has reviewed anything.
- Prompt interactively: doesn't work through `curl | sh` (stdin is the script).

### Decision 9 — comin is the source of truth for "is this host push-to-deploy"

**Choice:** whether a host runs `xi ... switch .` locally after a push is a property of the host's *profile*, declared as `comin = { enabled = ...; remote = ...; branch = ...; }` in `dotfiles.profiles.<host>` and enforced by `dot deploy` at runtime (see deploy spec, "dot deploy is comin-aware" requirement). `dot` MUST NOT try to talk to the comin daemon directly — the nix declaration is the contract, and comin's actual state is only surfaced informationally via `dot doctor`'s `comin-configured` check.

**Rationale:** comin's runtime state (systemd unit, last-poll timestamp, remote reachability) is inspectable but noisy and race-prone. Making `dot deploy`'s dispatch depend on a live probe would create a heisenbug class where the same command means different things depending on daemon health. Pinning the decision in the profile makes it auditable in git, reversible in one commit, and reproducible across sessions. `dot doctor` still shows the live state so a human/agent can spot drift (profile says `enabled = true` but the unit is masked, for instance) without that drift silently changing `dot deploy`'s behavior.

**Alternatives considered:**

- Probe `systemctl is-active comin` at every `dot deploy`: introduces a runtime dependency on systemd internals and races with unit reloads.
- Make `dot deploy` always local-apply and let the user "just not run it" on comin hosts: relies on discipline; agents will forget; the whole point is to encode this in the tool.
- Add a `--comin-enabled=auto|true|false` CLI flag with detection: three-way flags are footguns; the profile is one source of truth.

### Decision 10 — Repo lives under `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles`, not `$HOME/ghq/...`

**Choice:** `install.sh` clones into `${DOTFILES_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles}` and `dot`'s flake-root discovery falls back to the same path. The user's own historical clone path (`$HOME/ghq/github.com/Dauliac/dotfiles`) is not honored as a fallback by `dot`.

**Rationale:** the XDG Base Directory Specification puts a git working tree that's "user data managed by an application" under `$XDG_DATA_HOME`, not `$XDG_CONFIG_HOME` (which is for the app's *own* config files) and not `$HOME/ghq/...` (which is a tool-specific convention). Choosing `$XDG_DATA_HOME/dotfiles` makes `dot`'s first-run behavior identical on any host without users having to know about `ghq`, and cleanly separates the flake from the user's other git checkouts. Users who prefer the ghq layout can point `$DOT_FLAKE_ROOT` at their existing clone — one env var, no code change.

**Alternatives considered:**

- `$XDG_CONFIG_HOME/dotfiles`: violates XDG's data/config split — the flake contains derivations, lockfiles, generated caches, not just declarative config.
- `$HOME/ghq/...`: leaks the user's `ghq` habit into the tool's defaults; breaks on hosts where `ghq` isn't set up.
- `$HOME/.dotfiles`: unhidden semantics are fine on personal machines but conflict with XDG on shared/system-manager hosts.

### Decision 7 — Schema-versioned JSON, additive-only until v2

**Choice:** `schema_version` is an integer starting at `1`. Adding fields to `data` does NOT bump it; removing/renaming DOES. The `SKILL.md` declares `min_schema_version` and refuses to drive an older binary.

**Rationale:** agents pin against a spec surface; silent renames break them. Additive-only lets us extend without churn. Two-track versioning (skill-side minimum, binary-side actual) means an old flake on a machine won't be driven by a newer skill that expects fields it can't emit.

**Alternatives considered:**

- SemVer strings: overkill for one struct.
- No versioning: bites on the first rename.

### Decision 8 — `dotfiles.scopes` lives at repo `modules/generic/scopes.nix` (or per-scope files under `modules/dotfiles/scopes/*.nix`)

**Choice:** define `dotfiles.scopes` and `dotfiles.profiles` as `nlib`-typed options in a new `modules/dotfiles/` subtree, with one file per scope. import-tree picks them up automatically, matching the dendritic pattern.

**Rationale:** keeps each scope self-contained (owner-per-file), scales as new scopes are added, and mirrors the existing organization under `modules/home-manager/programs/*.nix`.

**Alternatives considered:**

- Single monolithic `scopes.nix`: violates dendritic pattern.
- Colocate each scope's declaration next to its owning module: harder to enumerate; nix eval walks unrelated modules.

## Risks / Trade-offs

- **Risk**: `nix eval` on a cold store is slow (>1 s), making `dot detect` feel laggy on a fresh clone.
  → **Mitigation**: parallelize the two eval calls (profiles, scopes); document expected first-invocation latency in `SKILL.md`; add `dot --version` short-path that doesn't eval.
- **Risk**: `curl | sh` invocation on non-NixOS could leave a half-installed state if the Determinate installer succeeds but the clone step fails.
  → **Mitigation**: `install.sh` prints a `resume: …` line on any failure (bootstrap spec Requirement 6) so a human or agent can pick up mid-way without re-running from scratch.
- **Risk**: JSON schema drift between `dot` and `SKILL.md` if they're versioned independently.
  → **Mitigation**: skill lives inside the flake and gets bumped in the same commit as the binary; `min_schema_version` check enforces the contract at runtime.
- **Risk**: profile misdetection on a hostname rename (already happened once with `ML-PF59GCGW` → `ML-PF603JJ8`).
  → **Mitigation**: `hostnameAliases` in the nix profile submodule; explicit test case in `scopes` and `deploy` specs; documented in `SKILL.md`.
- **Risk**: `dot deploy` on a home-manager host also happens to be safe on NixOS (since `xi home switch` is also valid there), so an agent could hide a wrong classification.
  → **Mitigation**: `dot detect --json` is the source of truth the skill instructs the agent to read *before* deploy; `dot doctor` reports the resolved profile too.
- **Risk**: `dot patch` writing to a file that later fails to `nix build` locks the agent in a repair loop.
  → **Mitigation**: the five-step E2E flow is explicitly `patch → build → deploy → commit → push` (deploy spec Requirement 6). `build` must succeed before `deploy`, and neither `commit` nor `push` is auto-chained.
- **Trade-off**: refusing on-disk config caching means we pay the nix-eval cost every call. Acceptable — the correctness win from "one source of truth" outweighs the ~200 ms cost.
- **Trade-off**: `dot commit` is conventional-commit-only, which will feel restrictive for freeform amends and merge commits. Acceptable — those are rare enough that `git commit` directly (which `dot` never blocks) covers them.

## Migration Plan

1. Land `modules/dotfiles/{profiles.nix,scopes/*.nix}` first — they're pure nix, `dot` isn't shipped yet, and they can be consumed by hand via `nix eval` for early validation. Include the `comin` sub-submodule in the profile type from day one; default `comin.enabled = false` for every existing host.
2. Land `pkgs/dot/` (Rust workspace + `default.nix` using `crane`) with subcommands stubbed to return `todo` under `--json` but exit `0`. Verify `nix run .#dot -- detect --json` works pre-install.
3. Fill in subcommand bodies in priority order: `detect` → `status` → `doctor` → `build` → `deploy` → `patch` → `commit` → `push` → `bootstrap`. `deploy` MUST land with the comin-aware branch in the same commit as the local-apply branch — no interim commit that only understands one mode.
4. Add `install.sh` at repo root with the Lix installer + XDG-target clone + `nix run .#dot -- bootstrap --apply` sequence. Test on a throwaway Debian VM before advertising the `curl | sh` URL. Verify the clone target is `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles`, not `$HOME/ghq/...`, and that a subsequent `dot detect` from `/tmp` on the same VM finds the freshly cloned tree without any env-var handoff.
5. Add `modules/home-manager/ai/capability/skills/dot/SKILL.md` and verify it installs under `~/.claude/skills/dot/` after `xi home switch .`. The skill MUST document the push-first flow and the comin-vs-local-apply branch so an agent doesn't run `dot deploy` before `dot push`.
6. Update `redeploy.sh` (docs only) to mention `dot doctor` as the diagnostic step.
7. **Existing clone migration for the current user**: users with an existing `$HOME/ghq/github.com/Dauliac/dotfiles` checkout do NOT have to move it. They set `DOT_FLAKE_ROOT=$HOME/ghq/github.com/Dauliac/dotfiles` in their environment (e.g., via `home.sessionVariables` — remembering the `home.sessionPath` gotcha in MEMORY.md: this is a variable, not a PATH entry, so `home.sessionVariables` is correct) and `dot` will use that path instead of the XDG default. Only fresh clones land under XDG.
8. Rollback strategy: `dot` is additive. Reverting the change removes the binary and skill; `xi`, `redeploy.sh`, and any existing ghq clone are untouched. Any agent still on an old `SKILL.md` gracefully aborts via the `min_schema_version` check.

## Open Questions

- **Stable URL for `install.sh`**: raw.githubusercontent.com works but is CDN-cached with unpredictable TTLs. Do we accept that, or set up a short redirect (e.g., `dot.dauliac.sh` → the raw URL) later? Deferrable — proposal.md and specs don't depend on the answer.
- ~~**`dot bootstrap` on macOS**~~: **RESOLVED** — macOS is not supported. The user's targeted fleet is Debian and NixOS laptops only. `install.sh` explicitly exits `7` on Darwin (bootstrap spec, "OS detection" requirement). Revisit only if a darwin host is added to `dotfiles.profiles`.
