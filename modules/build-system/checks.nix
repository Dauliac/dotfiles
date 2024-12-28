_: {
  config.perSystem =
    {
      system,
      inputs',
      config,
      pkgs,
      ...
    }:
    {
      checks.default = pkgs.mkShell {
        buildInputs = with pkgs; checkPackages;
        shellHook = ''
          task check
        '';
      };
    };
}
