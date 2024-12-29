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
        homeManagerJdauliac = pkgs.stdenv.mkDerivation {
          name = "nixos-system";
          buildCommand = ''
            cp -r ${cfg.flake.homeConfigurations.jdauliac.activationPackage} $out
          '';
        };
        all = pkgs.stdenv.mkDerivation {
          name = "nixos-system";
          buildCommand = ''
            mkdir -p $out/{nixos/nixos,home-manager/jdauliac}
            cp -r ${config.packages.nixos} $out/nixos/nixos
            cp -r ${config.packages.homeManagerJdauliac} $out/home-manager/jdauliac
          '';
        };
        default = config.packages.all;
      };
    };
}
