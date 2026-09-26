{
  # Post-activation systemd user services — run once per home-manager
  # switch to wire up integrations that live outside nix (~/.claude.json,
  # ~/.config/opencode/*, etc.) but need to stay in sync with the current
  # generation of pkgs.codegraph.
  #
  # Pattern: oneshot user unit + activation hook that restarts it. The
  # restart forces re-execution even when the unit definition itself is
  # unchanged, which is what "run after every `xi home switch .`" means.
  # HM-managed files (~/.claude/CLAUDE.md is a store symlink with the
  # CODEGRAPH block baked in) are already idempotent for `codegraph
  # install` — it prints "Unchanged" and moves on.
  flake.modules.homeManager.ai-session-post-activate =
    {
      pkgs,
      lib,
      ...
    }:
    {
      systemd.user.services.codegraph-provision = {
        Unit = {
          Description = "Provision codegraph integrations for Claude Code + opencode";
          # Run after the graphical session so PATH/XDG dirs are settled.
          After = [ "default.target" ];
        };
        Service = {
          Type = "oneshot";
          Environment = [ "CODEGRAPH_TELEMETRY=0" ];
          ExecStart = "${pkgs.codegraph}/bin/codegraph install --yes";
        };
        Install.WantedBy = [ "default.target" ];
      };

      # Kick the oneshot on each `xi home switch .` — reloadSystemd has
      # already picked up any unit-file changes by this point, so all we
      # need is a nudge to re-run.
      home.activation.codegraphProvisionKick = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
        $DRY_RUN_CMD systemctl --user restart codegraph-provision.service || true
      '';
    };
}
