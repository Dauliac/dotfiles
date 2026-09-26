{
  # Global shell knobs. See example.toml [shell] section for the full list.
  # Everything is declared here; the runtime settings window is view-only —
  # writes to $XDG_STATE_HOME/noctalia/settings.toml fail because
  # declarative-lock.nix pins it to a read-only /nix/store path.
  flake.modules.homeManager.noctalia = {
    programs.noctalia.settings.shell = {
      telemetry_enabled = false;
      settings_show_advanced = false;
    };
  };
}
