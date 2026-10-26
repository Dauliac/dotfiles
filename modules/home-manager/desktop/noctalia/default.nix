{
  # noctalia's HM option namespace is `programs.noctalia` (v5 schema); the
  # module is registered globally in base via `inputs.noctalia.homeModules.default`.
  #
  # Runtime selection mirrors modules/home-manager/desktop/niri/default.nix:
  # driven by `systemConstants.nixgl.wrapperType`.
  #
  #   "system"       non-NixOS, distro-managed binary. On Debian the
  #                  nix-built noctalia links against a libpam that cannot
  #                  parse Debian's `@include`-based /etc/pam.d/login, so
  #                  the lock screen rejects every password with
  #                  PAM_PERM_DENIED (journal: "PAM (other) illegal module
  #                  type: @include" + "authentication failed rc=6"). PAM
  #                  service name is hardcoded to "login" upstream in
  #                  src/shell/lockscreen/lock_screen.cpp:863 with no config
  #                  knob, so the only viable fix is the Debian-native
  #                  binary against Debian libpam. Install path lives in
  #                  modules/system-manager.ML-PF603JJ8/default.nix (ansnix
  #                  apt-repo + apt-packages roles); binary lands at
  #                  /usr/bin/noctalia. HM module is kept for its
  #                  declarative config.toml / palettes stack; we hand-roll
  #                  the systemd user unit pointing at /usr/bin/noctalia.
  #
  #   anything else  NixOS or nixgl-wrapped host: install pkgs.noctalia and
  #                  let upstream's HM module wire its own systemd user
  #                  unit. Nix PAM has none of Debian's parsing issues.
  flake.modules.homeManager.noctalia =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      isSystemManaged = config.systemConstants.nixgl.wrapperType == "system";
    in
    {
      programs.noctalia = {
        enable = true;
      } // (
        if isSystemManaged then {
          package = null;
          systemd.enable = false;
          validateConfig = false;
        } else {
          package = pkgs.noctalia;
          systemd.enable = true;
          validateConfig = true;
        }
      );

      # Bongocat plugin reads /dev/input/event* through `evtest` (see
      # bar.nix:widget.bongocat). Install here so every host that imports
      # the noctalia module gets it  -  works for both nix-managed noctalia
      # and the Debian apt binary, since this just lands evtest in the
      # user profile. Per-host wiring still needs to add the user to the
      # `input` group (users.users.<name>.extraGroups on NixOS, or an
      # ansnix user-in-group role on Debian)  -  the plugin fails silently
      # without read access to the evdev nodes.
      home.packages = [ pkgs.evtest ];

      systemd.user.services.noctalia = lib.mkIf isSystemManaged {
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
