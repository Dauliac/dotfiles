{ inputs, ... }:
{
  # niri is configured via `sodiboo/niri-flake`'s home-manager module:
  # `programs.niri.{enable,package,settings,...}` and auto-configured
  # gnome-keyring + xdg-desktop-portal user services.
  #
  # Runtime selection is driven by `systemConstants.nixgl.wrapperType`:
  #
  #   - "none"                        NixOS host; niri from nixpkgs; no wrap
  #   - "intel"|"nvidia"|"mesa"|"auto" non-NixOS; niri from nixpkgs;
  #                                   ExecStart wraps in nixGL* so GL works
  #   - "system"                      non-NixOS with a distro-managed niri
  #                                   (e.g. DankLinux/Debian apt install);
  #                                   ExecStart runs /usr/bin/niri --session
  #                                   directly so the distro's mesa is used.
  #
  # niri-flake still generates config.kdl and the systemd user unit in
  # every case; we only rewrite ExecStart. `programs.niri.package` is
  # deliberately left as `pkgs.niri` so niri-flake can introspect
  # cargoBuildFeatures for portal-extras wiring.
  flake.modules.homeManager.niri =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      wrapperType = config.systemConstants.nixgl.wrapperType;
      nixGL =
        if wrapperType == "intel" then pkgs.nixgl.nixGLIntel
        else if wrapperType == "nvidia" then pkgs.nixgl.nixGLNvidia
        else if wrapperType == "mesa" then pkgs.nixgl.nixGLMesa
        else if wrapperType == "auto" then pkgs.nixgl.auto.nixGLDefault
        else null;
      nixGLBin =
        if wrapperType == "intel" then "nixGLIntel"
        else if wrapperType == "nvidia" then "nixGLNvidia"
        else if wrapperType == "mesa" then "nixGLMesa"
        else if wrapperType == "auto" then "nixGL"
        else null;

      execStart =
        if wrapperType == "system" then
          "/usr/bin/niri --session"
        else if nixGL != null then
          "${nixGL}/bin/${nixGLBin} ${pkgs.niri}/bin/niri --session"
        else
          null;
    in
    {
      imports = [
        inputs.niri-flake.homeModules.niri
        inputs.self.modules.generic.nixgl-wrapper
      ];

      programs.niri = {
        enable = true;
        package = pkgs.niri;
      };

      # Default terminal for launcher-invoked TUI apps (yazi from noctalia's
      # launcher, `.desktop` entries with Terminal=true, etc.). Two mechanisms
      # covered:
      #   - XDG_TERMINAL_EMULATOR: env var read by many launchers + GLib
      #   - ~/.config/xdg-terminals.list: freedesktop draft spec used by
      #     systemd's xdg-terminal-exec (first entry wins)
      home.sessionVariables.XDG_TERMINAL_EMULATOR = "kitty";
      xdg.configFile."xdg-terminals.list".text = ''
        kitty.desktop
        ghostty.desktop
        alacritty.desktop
        wezterm.desktop
      '';

      systemd.user.services.niri = lib.mkIf (execStart != null) {
        Service.ExecStart = lib.mkForce execStart;
        # Debian's /usr/lib/systemd/user/niri.service only `BindsTo` /
        # `Before` graphical-session.target — it doesn't actually start
        # it, so `WantedBy=graphical-session.target` services (noctalia,
        # xwayland-satellite, polkit-gnome, wallpaper) never fire.
        #
        # `graphical-session.target` sets `RefuseManualStart=yes`, so a
        # `systemctl start` won't work — the only way in is a dependency
        # pull. Adding `Wants=` here makes systemd schedule the target
        # to activate as a dependency of niri.service starting, which
        # bypasses the manual-start refusal.
        Unit.Wants = [ "graphical-session.target" ];
      };
    };
}
