_: {
  config.perSystem = { config, ... }: {
    pre-commit.settings.hooks = {
      treefmt = {
        enable = true;
        package = config.treefmt.build.wrapper;
      };
      deadnix.enable = true;
      statix.enable = true;
    };
  };
}
