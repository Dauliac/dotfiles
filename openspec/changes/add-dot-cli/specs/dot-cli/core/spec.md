## Purpose

Defines the `dot` binary's user-facing contract: the CLI framing, the stable JSON output shape, the exit-code semantics, and the host/profile detection every other `dot` subcommand consumes. This is the layer that lets an AI agent invoked from any working directory reason about the current host and dispatch the right downstream `xi`/`git` action without re-deriving that logic each session.

## ADDED Requirements

### Requirement: dot binary is discoverable from any working directory

The `dot` binary SHALL locate the dotfiles flake by (in order): walking upward from `$PWD` for a `flake.nix` whose top-level module set contains `dotfiles.profiles`, falling back to `$DOT_FLAKE_ROOT` when set, and finally to `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles`. `dot` MUST NOT hard-code a single absolute path and MUST NOT treat any `$HOME/ghq/...` path as a fallback.

#### Scenario: invoked from inside the flake

- **WHEN** the user runs `dot status` from any directory under the flake root
- **THEN** `dot` resolves the flake root by walking upward and reports its resolved path in `status.flake_root`

#### Scenario: invoked from outside the flake without env override, XDG_DATA_HOME set

- **WHEN** the user runs `dot status` from `/tmp` with `XDG_DATA_HOME=/home/u/.local/share` and `$DOT_FLAKE_ROOT` unset
- **THEN** `dot` falls back to `/home/u/.local/share/dotfiles` and reports it in `status.flake_root`

#### Scenario: invoked from outside the flake without env override, XDG_DATA_HOME unset

- **WHEN** the user runs `dot status` from `/tmp` with `$XDG_DATA_HOME` and `$DOT_FLAKE_ROOT` both unset
- **THEN** `dot` falls back to `$HOME/.local/share/dotfiles` and reports it in `status.flake_root`

#### Scenario: invoked with explicit override

- **WHEN** the user runs `DOT_FLAKE_ROOT=/opt/dots dot status`
- **THEN** `dot` uses `/opt/dots` as the flake root regardless of `$PWD` and `$XDG_DATA_HOME`

### Requirement: stable JSON output on --json

Every `dot` subcommand SHALL accept a `--json` flag. When `--json` is present, `dot` MUST write a single JSON document to stdout, MUST NOT interleave human-readable text on stdout, and MUST route all logs, prompts, and progress to stderr. The JSON document SHALL contain, at minimum, the fields `command`, `schema_version` (integer, currently `1`), `status` (`"ok"` or `"error"`), and `data` (subcommand-specific). Additive changes to `data` MUST NOT bump `schema_version`; removals or renames MUST bump it.

#### Scenario: agent parses status output

- **WHEN** an agent runs `dot status --json`
- **THEN** stdout is a single JSON object with `command == "status"`, `schema_version == 1`, `status == "ok"`, and a `data` object with `flake_root`, `hostname`, `profile`, and `scopes`

#### Scenario: subcommand fails under --json

- **WHEN** `dot deploy --json` fails because `xi` returned a non-zero exit
- **THEN** stdout is still a single JSON object with `status == "error"` and a `data.error` object with `code`, `message`, and `stderr_tail`

### Requirement: deterministic exit codes

`dot` SHALL use the following exit codes and MUST NOT reuse them for unrelated failures: `0` success; `2` usage error (bad flags, unknown subcommand); `3` no matching profile for the current host; `4` flake evaluation failed; `5` downstream `xi` failed; `6` downstream `git` failed; `7` bootstrap precondition failed (nix missing on non-NixOS after install attempt); `10` user aborted (Ctrl-C or `--yes` not passed to a destructive command). Codes `1` and `8`-`9` are reserved.

#### Scenario: unknown host

- **WHEN** the user runs `dot deploy` on a host whose name is not registered in `dotfiles.profiles`
- **THEN** `dot` exits `3` and, under `--json`, `data.error.code == "no-matching-profile"`

#### Scenario: xi failure propagates

- **WHEN** `xi home switch .` exits non-zero
- **THEN** `dot deploy` exits `5` and, under `--json`, `data.error.stderr_tail` contains the last 40 lines of xi's stderr

### Requirement: detect subcommand reports host resolution

`dot detect` SHALL, without side effects, print the detected hostname, the matched profile record (or none), the OS family (`nixos`, `debian`, `ubuntu`, `other`), whether Nix/Lix is on `PATH`, and the current host's comin status. Under `--json` the same information MUST appear under `data`, including a `data.comin` object with the fields `{ enabled: bool, remote: string|null, branch: string|null, last_seen: string|null }` (RFC 3339 timestamp when known). macOS is intentionally NOT a supported OS family value.

#### Scenario: NixOS host with matching profile, comin enabled

- **WHEN** the user runs `dot detect --json` on `spongebob` and `spongebob`'s profile declares `comin.enabled == true`
- **THEN** `data.hostname == "spongebob"`, `data.profile.kind == "os"`, `data.os_family == "nixos"`, `data.nix_available == true`, and `data.comin.enabled == true` with `data.comin.remote` and `data.comin.branch` populated from the profile

#### Scenario: non-NixOS host, no nix yet, no comin

- **WHEN** the user runs `dot detect --json` on a fresh Debian box where nix is not installed and no comin is configured
- **THEN** `data.os_family == "debian"`, `data.nix_available == false`, `data.profile` is `null` if no matching entry exists in `dotfiles.profiles`, and `data.comin.enabled == false` with the other `comin` fields `null`

#### Scenario: unsupported OS family

- **WHEN** the user runs `dot detect --json` on a host whose `/etc/os-release` is missing or unrecognised
- **THEN** `data.os_family == "other"` and no `data.os_family` value equals `"macos"`

### Requirement: --dry-run for every mutating subcommand

Every subcommand that would mutate the system, the git tree, or a remote (`patch`, `build`, `deploy`, `commit`, `push`) SHALL accept `--dry-run`. Under `--dry-run`, `dot` MUST print the exact commands it would run (one per line under `data.plan[]` in JSON mode) and MUST NOT execute them.

#### Scenario: dry-run deploy on system-manager host

- **WHEN** the user runs `dot deploy --dry-run --json` on the system-manager host
- **THEN** `data.plan` contains an entry with `argv == ["xi", "system", "switch", "."]` and no `xi` process is spawned

### Requirement: doctor subcommand references the break-glass path and reports comin

`dot doctor` SHALL check that (a) the flake root is a git working tree, (b) `xi` is on `PATH`, (c) `nix`/`lix` is on `PATH`, (d) `redeploy.sh` is present and executable at the flake root, (e) whether comin is configured for this host (`comin-configured`). When any check fails, `dot doctor` MUST print the exact remediation command in stderr, and its JSON output MUST include a `data.checks[]` array with `{name, ok, hint}` entries. The `comin-configured` check is INFORMATIONAL only — it MUST NOT cause `dot doctor` to exit non-zero when `ok == false`, because comin is optional on this repo's hosts.

#### Scenario: PATH stripped after a bad deploy

- **WHEN** `nix` is not on `PATH` and the user runs `dot doctor`
- **THEN** `data.checks` includes `{name: "nix-on-path", ok: false, hint: "run ./redeploy.sh from the flake root"}` and stderr echoes the hint

#### Scenario: comin is configured

- **WHEN** the profile for the current host has `comin.enabled == true` and the comin service can be introspected
- **THEN** `data.checks` includes `{name: "comin-configured", ok: true, hint: "push-to-deploy: comin at <remote>/<branch> will apply on next tick"}` and `dot doctor` exits `0`

#### Scenario: comin is not configured

- **WHEN** the profile for the current host has `comin.enabled == false` (or the field is absent)
- **THEN** `data.checks` includes `{name: "comin-configured", ok: false, hint: "local-apply mode: run `dot deploy` after `dot push` to converge"}` AND `dot doctor` STILL exits `0` (informational only)
