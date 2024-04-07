{
  inputs,
  lib,
  ...
}: let
  inherit (lib) mkOption mdDoc types;
  inherit (inputs.flake-parts.lib) mkPerSystemOption;
in {
  options.perSystem = mkPerSystemOption ({
    pkgs,
    config,
    ...
  }: {
    options = {
      linters = mkOption {
        description = mdDoc "Packages used to lint the repo";
        type = types.listOf types.package;
        default = with pkgs; [
          typos
          go-task
          yamlfmt
        ];
      };
    };
  });
  config.perSystem = {
    system,
    inputs',
    config,
    pkgs,
    ...
  }: {
    checks.default = pkgs.mkShell {
      buildInputs = with pkgs; checkPackages;
      shellHook = ''
        task check
      '';
    };
  };
}
