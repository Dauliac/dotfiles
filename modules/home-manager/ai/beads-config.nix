{
  # Beads hook-clobber guard.
  #
  # Go bd (gastownhall/beads) installs git hooks into `.git/hooks/*` by
  # default on `bd init`, and no persistent YAML config key exists to
  # disable that behavior — verified against `docs/reference/git-integration.md`
  # and `internal/hooks/hooks.go` on `main` as of 2026-09-11 (see design.md
  # D3 in openspec change beads-go-migration-and-dolt-caps).
  #
  # The only durable enforcement is periodic reconciliation:
  #   - `bd init --skip-hooks` at first init (per-repo bootstrap)
  #   - `bd hooks uninstall` retroactively when shims are detected
  #
  # We enforce it on every home-manager activation via a sweep of
  # `~/ghq/**/.beads/`. Sweep is cheap (bd hooks status is a stat call);
  # scoped to ghq to avoid brushing arbitrary $HOME paths. The Claude
  # SessionStart hook in `session/beads-hook-guard.nix` handles per-repo
  # runtime enforcement (see task 4.2).
  flake.modules.homeManager.beads-config =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      beadsBin = "${pkgs.beads}/bin/bd";
      ghqRoot = "${config.home.homeDirectory}/ghq";
    in
    {
      # Silences bd's `git config beads.role` warning. Go bd stores
      # `beads.role` in git config (per docs/reference/configuration.md).
      # `~/.config/git/config` is a nix-store symlink, so `git config
      # --global beads.role maintainer` can't write to it — declare it
      # here instead. Preserved from the pre-refactor beads.nix module
      # (deleted in commit 200e834's refactor lineage) so the warning
      # does not return after xi home switch.
      programs.git.settings.beads.role = "maintainer";

      # One shell helper on PATH so the user can run it manually per-repo
      # (`beads-hook-guard` inside a repo → uninstalls beads shims if any).
      home.file.".local/bin/beads-hook-guard" = {
        executable = true;
        text = ''
          #!${pkgs.runtimeShell}
          # beads-hook-guard — remove beads-installed shims from .git/hooks/
          # if bd hooks status reports them installed. Idempotent + safe:
          # exits 0 whether or not any action was taken.
          set -eu
          repo=''${1:-.}
          cd "$repo" 2>/dev/null || {
            echo "beads-hook-guard: repo not readable: $repo" >&2
            exit 0
          }
          # Only act inside a git repo that has a .beads/ dir.
          [ -d .git ] && [ -d .beads ] || exit 0
          # bd hooks status exits 0 regardless; parse the output to decide.
          if ${beadsBin} hooks status 2>/dev/null | grep -qiE 'installed|active|present'; then
            echo "beads-hook-guard: uninstalling beads shims in $PWD" >&2
            ${beadsBin} hooks uninstall 2>/dev/null || true
          fi
        '';
      };

      # Home-manager activation sweep — runs once per `xi home switch`.
      # Kept cheap: only walks ~/ghq/**/.beads (project sandbox typical),
      # and only invokes `bd hooks uninstall` when status shows shims present.
      home.activation.beadsHookGuardSweep =
        lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
          # NB: exit 0 always — we do not want a stray beads state to block
          # the whole home-manager switch. Individual failures are logged
          # to stderr.
          if [ -d ${lib.escapeShellArg ghqRoot} ]; then
            find ${lib.escapeShellArg ghqRoot} -maxdepth 5 -type d -name .beads 2>/dev/null | while IFS= read -r beadsDir; do
              repo=''${beadsDir%/.beads}
              [ -d "$repo/.git" ] || continue
              # Only call bd if there's actually a bead DB to look at.
              [ -f "$beadsDir/beads.db" ] || [ -d "$beadsDir/embeddeddolt" ] || continue
              ( cd "$repo" && ${beadsBin} hooks status 2>/dev/null | grep -qiE 'installed|active|present' && {
                  echo "beadsHookGuardSweep: uninstalling shims in $repo" >&2
                  ${beadsBin} hooks uninstall 2>/dev/null || true
                } ) || true
            done
          fi
        '';

      # Claude Code SessionStart hook — per-repo enforcement at session
      # start. Complements the activation sweep: covers cases where a
      # user runs `bd init` mid-session or clones a new repo. Merged into
      # ~/.claude/settings.json by claude-settings-merge (see
      # modules/home-manager/ai/claude-settings.nix); coexists with the
      # scratch-index hook (10-scratch.json) and any others.
      home.file.".claude/settings.d/20-beads-hook-guard.json".text =
        builtins.toJSON {
          hooks.SessionStart = [
            {
              matcher = "*";
              hooks = [
                {
                  type = "command";
                  command = "${config.home.homeDirectory}/.local/bin/beads-hook-guard \"$CLAUDE_PROJECT_DIR\"";
                  timeout = 5;
                }
              ];
            }
          ];
        };
    };
}
