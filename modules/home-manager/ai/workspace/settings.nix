{
  # Deep-merges nix-owned settings fragments into ~/.claude/settings.json on
  # every home-manager activation, without clobbering runtime writes by
  # Claude Code, codegraph, or the ManoMano CLIs.
  #
  # Contract for contributor modules:
  #
  #   home.file.".claude/settings.d/<order>-<name>.json".text =
  #     builtins.toJSON { hooks.SessionStart = [ ... ]; };
  #
  # Order prefix (10-, 20-, ...) fixes fragment application order for
  # reproducibility; semantically the deep-merge is commutative for the
  # rules we implement, but stable ordering makes drift easier to diff.
  #
  # Retraction: the deep-merge is forward-only, so removing a contributor
  # module does NOT drop its stale hooks from ~/.claude/settings.json.
  # `retiredHookCommands` below is the escape hatch — regex fragments
  # matched against .hooks[.event][].hooks[0].command; matching entries
  # are pruned from the base on every activation. Add a fragment when you
  # retire a nix-owned hook whose command was baked into $target during a
  # previous switch. Backup at ~/.claude/settings.json.pre-merge lets you
  # diff either kind of change.
  flake.modules.homeManager.ai-workspace-settings =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      mergeJq = ./settings/merge.jq;
      retiredHookCommands = [
        "dispatch-guard"
        "dispatch-state"
      ];
      retiredRegex = lib.concatStringsSep "|" retiredHookCommands;
      claude-settings-merge = pkgs.writeShellApplication {
        name = "claude-settings-merge";
        runtimeInputs = with pkgs; [
          jq
          coreutils
          diffutils
        ];
        text = ''
          # Deep-merge every fragment under ~/.claude/settings.d/*.json into
          # ~/.claude/settings.json. Idempotent, safe to re-run.

          target="''${1:-$HOME/.claude/settings.json}"
          frags_dir="''${2:-$HOME/.claude/settings.d}"
          merge_expr="${mergeJq}"

          mkdir -p "$(dirname "$target")"
          [[ -f "$target" ]] || printf '{}\n' > "$target"

          if [[ ! -d "$frags_dir" ]]; then
            echo "claude-settings-merge: no fragments dir at $frags_dir, skipping" >&2
            exit 0
          fi

          shopt -s nullglob
          # Sort by filename for stable ordering across activations.
          # -xtype f resolves symlinks and matches only when the target is a
          # regular file, so dangling links (e.g. left behind by an aborted
          # earlier switch) are skipped instead of crashing jq.
          mapfile -t frags < <(find "$frags_dir" -maxdepth 1 -xtype f -name '*.json' | sort)
          if (( ''${#frags[@]} == 0 )); then
            echo "claude-settings-merge: no *.json fragments, skipping" >&2
            exit 0
          fi

          tmp=$(mktemp)
          trap 'rm -f "$tmp"' EXIT

          jq -s --arg retired '${retiredRegex}' -f "$merge_expr" "$target" "''${frags[@]}" > "$tmp"

          if cmp -s "$target" "$tmp"; then
            echo "claude-settings-merge: no changes (''${#frags[@]} fragment(s) already applied)"
            exit 0
          fi

          # Snapshot the previous file before overwriting so retraction is
          # possible by diff.
          cp -f "$target" "$target.pre-merge"
          mv "$tmp" "$target"
          chmod 600 "$target"
          echo "claude-settings-merge: merged ''${#frags[@]} fragment(s) into $target (backup at $target.pre-merge)"
        '';
      };
    in
    {
      home.packages = [ claude-settings-merge ];

      # Ship the jq expression at a stable path too so ad-hoc invocations
      # (debugging, manual re-merges) don't need to know the store path.
      home.file.".claude/hooks/claude-settings-merge.jq".source = mergeJq;

      # Run the merge on every activation, after `home.file` links are
      # guaranteed to be in place (writeBoundary). This runs inside
      # home-manager-''${user}.service — the systemd user unit that owns
      # home-manager activation — so it's "systemd activation" in the
      # sense the user meant.
      home.activation.claudeSettingsMerge = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${claude-settings-merge}/bin/claude-settings-merge \
          "${config.home.homeDirectory}/.claude/settings.json" \
          "${config.home.homeDirectory}/.claude/settings.d"
      '';
    };
}
