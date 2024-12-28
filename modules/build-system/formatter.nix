{
  lib,
  inputs,
  ...
}: let
  inherit (lib) mkOption mdDoc types;
  inherit (inputs.flake-parts.lib) mkPerSystemOption;
in {
  options.perSystem = mkPerSystemOption ({pkgs, ...}: {
    options = {
      formatterPackages = mkOption {
        description = mdDoc "Packages used to format the repo";
        default = with pkgs; [alejandra statix];
        type = types.listOf types.package;
      };
    };
  });
  config.perSystem = {
    config,
    pkgs,
    ...
  }: {
    formatter = pkgs.writeShellApplication {
      name = "normalise-nix";
      runtimeInputs = config.formatterPackages;
      text = ''
        set -o xtrace
        ${pkgs.alejandra}/bin/alejandra "$@"
        ${pkgs.statix}/bin/statix fix "$@"
      '';
    };
  };
}
