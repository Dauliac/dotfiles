{ inputs, ... }: {
  flake.modules.homeManager.xi = {
    disabledModules = [ "programs/nh.nix" ]; # use xi flake's module instead of upstream nh
    imports = [ inputs.xi.homeManagerModules.default ];

    programs.xi = {
      enable = true;
      shellHook = {
        enable = true;
        nixAlias = true;
        completion = true;
        develop = true;
      };
    };

    # Route xi's privilege elevation through pkexec instead of sudo. pkexec
    # authorizations trigger the polkit-gnome agent (see niri/session.nix),
    # so `xi system switch .` and friends pop up a graphical prompt instead
    # of a TTY `[sudo] password:` line. Override per-invocation with
    # `xi -e sudo …` on headless / SSH sessions without a polkit agent.
    home.sessionVariables.XI_ELEVATION_STRATEGY = "pkexec";
  };
}
