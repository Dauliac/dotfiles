{
  # noctalia's HM option namespace is `programs.noctalia` (v5 schema); the
  # module is registered globally in base via `inputs.noctalia.homeModules.default`.
  #
  # The noctalia BINARY is intentionally NOT installed via nix on this host.
  # The nix-built noctalia links against a libpam that cannot parse Debian's
  # `@include`-based /etc/pam.d/login, so the lock screen rejects every
  # password with PAM_PERM_DENIED — journal shows repeated:
  #   "PAM (other) illegal module type: @include"
  #   "[pam] authentication failed for user='…' rc=6 (Permission denied)"
  # The PAM service name is hardcoded to "login" upstream
  # (src/shell/lockscreen/lock_screen.cpp:863) with no config knob, so the
  # only viable fix is to use the Debian-native binary against Debian libpam.
  # Install path lives in modules/system-manager.ML-PF603JJ8/default.nix
  # (ansnix apt-repo + apt-packages roles); binary lands at /usr/bin/noctalia.
  #
  # We keep the HM module for its declarative config.toml / palettes stack,
  # so we set:
  #   package = null      → drops noctalia from home.packages,
  #                         skips the `noctalia config validate` runCommand.
  #   systemd.enable = false
  #                       → upstream unit's ExecStart = getExe cfg.package
  #                         and asserts package != null; we own the unit.
  #   validateConfig = false
  #                       → xdg.configFile's runCommand also calls getExe on
  #                         cfg.package; disable so config.toml is written
  #                         verbatim. Noctalia will surface bad config at
  #                         runtime instead of build time.
  # A hand-rolled user unit ExecStart's /usr/bin/noctalia. PartOf /
  # After / WantedBy track home-manager's wayland target so it stops and
  # restarts alongside the compositor session (matches upstream unit).
  flake.modules.homeManager.noctalia = { config, ... }: {
    programs.noctalia = {
      enable = true;
      package = null;
      systemd.enable = false;
      validateConfig = false;
    };

    systemd.user.services.noctalia = {
      Unit = {
        Description = "Noctalia - A lightweight Wayland shell and bar (apt-installed binary)";
        Documentation = "https://docs.noctalia.dev/noctalia/";
        PartOf = [ config.wayland.systemd.target ];
        After = [ config.wayland.systemd.target ];
      };
      Service = {
        ExecStart = "/usr/bin/noctalia";
        Restart = "on-failure";
      };
      Install.WantedBy = [ config.wayland.systemd.target ];
    };
  };
}
