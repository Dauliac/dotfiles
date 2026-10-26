{
  # Global shell knobs. See example.toml [shell] section for the full list.
  # Everything is declared here; the runtime settings window is view-only —
  # writes to $XDG_STATE_HOME/noctalia/settings.toml fail because
  # declarative-lock.nix pins it to a read-only /nix/store path.
  flake.modules.homeManager.noctalia = {
    programs.noctalia.settings.shell = {
      telemetry_enabled = false;
      settings_show_advanced = false;
      # Suppress the first-run setup wizard panel. Upstream also gates on a
      # `.setup-complete` marker file in $XDG_STATE_HOME/noctalia/, but this
      # flag short-circuits shouldRunSetupWizard() regardless of marker state
      # (see src/config/config_service.cpp:679).
      setup_wizard_enabled = false;
    };
  };
}
