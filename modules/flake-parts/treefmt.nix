{ ... }: {
  config.perSystem =
    { ... }:
    {
      treefmt = {
        programs = {
          shfmt.enable = true;
          shellcheck.enable = true;
          alejandra.enable = true;
          nixfmt.enable = true;
          jsonfmt.enable = true;
          stylua.enable = true;
          statix.enable = true;
        };
      };
    };
}
