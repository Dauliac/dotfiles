## Purpose

Defines the zero-to-working install path — a `curl … | sh` one-liner that lands `dot` (and the dotfiles flake) on a Linux laptop, either NixOS or Debian/Ubuntu, without the user knowing which of Lix, xi, or git is missing. macOS is explicitly not a supported target. This is the "new laptop" experience that the AI-driven workflow depends on for reproducibility.

## ADDED Requirements

### Requirement: single-file installer served from the repo

The bootstrap script SHALL live as `install.sh` at the flake root, be POSIX-`sh` compatible (not bash-only), and be safe to pipe from a URL (`set -eu`, no unquoted expansions, no `read` from stdin because stdin is the script). Piped invocation is expected to look like `curl -fsSL <URL>/install.sh | sh`.

#### Scenario: piped invocation on a fresh Debian box

- **WHEN** a user runs `curl -fsSL https://raw.githubusercontent.com/Dauliac/dotfiles/master/install.sh | sh` on a fresh Debian install
- **THEN** the script runs to completion under `/bin/sh`, exits `0`, and leaves `dot` on `PATH` in a new login shell

### Requirement: OS detection and Lix provisioning

`install.sh` SHALL detect the OS family via `/etc/os-release` and `uname`. On NixOS, it MUST skip the Lix-install step (nix is already provided by the system). On Debian/Ubuntu, if `nix` (or `lix`) is not on `PATH`, it MUST invoke the Lix installer non-interactively via `curl -sSf -L https://install.lix.systems/lix | sh -s -- install --no-confirm` (setting `NIX_INSTALLER_NO_CONFIRM=1` as belt-and-suspenders, since the Lix installer script requires either the flag or the env var when stdin is not a TTY, per the upstream installer script's line-123 check), then re-source `/etc/profile.d/nix.sh` so subsequent steps see `nix` on `PATH`. On macOS, or any other OS family that is not NixOS/Debian/Ubuntu, it MUST exit `7` — macOS is explicitly not supported until a darwin host exists in `dotfiles.profiles`.

#### Scenario: NixOS, nix already present

- **WHEN** `install.sh` runs on NixOS
- **THEN** the Lix installer is not invoked, and the script proceeds directly to the flake-clone step

#### Scenario: Debian, no nix

- **WHEN** `install.sh` runs on Debian and `command -v nix` fails
- **THEN** the Lix installer is invoked exactly as `curl -sSf -L https://install.lix.systems/lix | sh -s -- install --no-confirm` (with `NIX_INSTALLER_NO_CONFIRM=1` exported) and, after it succeeds, `nix --version` prints a version on the same shell

#### Scenario: macOS

- **WHEN** `install.sh` detects Darwin via `uname -s`
- **THEN** it exits `7` with the message `error: macOS is not a supported target of this dotfiles bootstrap; see openspec/specs/dot-cli/bootstrap/spec.md`

#### Scenario: Unsupported OS

- **WHEN** `install.sh` runs on a non-NixOS, non-Debian, non-Ubuntu, non-Darwin OS whose family it cannot classify
- **THEN** it exits `7` with a message that includes the values of `ID` and `ID_LIKE` from `/etc/os-release`

### Requirement: flake clone with idempotent target

`install.sh` SHALL clone the dotfiles flake into `${DOTFILES_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles}`. The resolved path MUST match the fallback chain defined in the `core` capability spec's "dot binary is discoverable" requirement so that the freshly-cloned tree is immediately findable by the newly-installed `dot` binary without any env-var handoff. If the target directory already exists and is a git working tree with the correct `origin` remote, the script MUST `git pull --ff-only` instead of failing. If the target exists but is not the correct working tree, the script MUST refuse and exit `7`. `install.sh` MUST NOT clone into `$HOME/ghq/...` or any other legacy path.

#### Scenario: fresh clone

- **WHEN** the target directory does not exist
- **THEN** `install.sh` clones `git@github.com:Dauliac/dotfiles.git` (or `https://…` fallback if no ssh key) into the target

#### Scenario: existing clone

- **WHEN** the target directory is already the dotfiles working tree
- **THEN** `install.sh` runs `git pull --ff-only` and continues

#### Scenario: unrelated directory in the way

- **WHEN** the target directory exists but is empty or contains an unrelated git repo
- **THEN** `install.sh` exits `7` with `error: refusing to overwrite <path>` and does not touch the directory

### Requirement: initial converge via nix run

`install.sh` SHALL perform the first converge by invoking `nix run "$DOTFILES_ROOT#dot" -- bootstrap --apply` from the newly cloned flake, so that the very first materialization of `dot` comes from the flake itself and stays in lockstep with the checked-out sources. `install.sh` MUST NOT invoke `xi` directly — the flake-provided `dot bootstrap --apply` owns that call.

#### Scenario: first-time converge on non-NixOS

- **WHEN** the flake is freshly cloned on a Debian box
- **THEN** `install.sh` runs `nix run "$DOTFILES_ROOT#dot" -- bootstrap --apply`, which internally runs `xi home switch .` and finishes with `dot` on the login PATH

### Requirement: installer prints a resumption hint on any non-zero exit

If any step fails, `install.sh` SHALL print, on stderr, the exact command needed to resume from that step (e.g., `resume: cd $DOTFILES_ROOT && nix run .#dot -- bootstrap --apply`), so a user or agent can pick up mid-install without re-running the whole pipe-to-sh.

#### Scenario: partial install after network hiccup

- **WHEN** `install.sh` gets past the clone step but the initial `nix run` fails due to a transient network error
- **THEN** stderr contains a line `resume: cd <path> && nix run .#dot -- bootstrap --apply` and the exit code identifies which phase failed
