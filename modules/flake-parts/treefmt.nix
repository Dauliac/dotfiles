_: {
  config.perSystem = _: {
    treefmt = {
      programs = {
        shfmt.enable = true;
        shellcheck.enable = true;
        alejandra.enable = true;
        nixfmt.enable = true;
        deadnix.enable = true;
        nixf-diagnose.enable = true;
        jsonfmt.enable = true;
        stylua.enable = true;
        statix.enable = true;
      };
    };
  };
}
