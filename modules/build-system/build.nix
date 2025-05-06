{ config, ... }:
let
  cfg = config;
in
{
  config.perSystem =
    {
      pkgs,
      config,
      ...
    }:
    {
      packages = {
        nixos = pkgs.stdenv.mkDerivation {
          name = "nixos-system";
          buildCommand = ''
            cp -r ${cfg.flake.nixosConfigurations.nixos.config.system.build.toplevel} $out
          '';
        };
        homeManager = pkgs.stdenv.mkDerivation {
          name = "nixos-system";
          buildCommand = ''
            cp -r ${cfg.flake.nixosConfigurations.nixos.config.system.build.toplevel} $out
          '';
        };
        default = config.packages.nixos;
      };
    };
}
