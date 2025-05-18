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
        homeManagerJulienDauliac = pkgs.stdenv.mkDerivation {
          name = "home-manager-system";
          buildCommand = ''
            cp -r ${builtins.head cfg.flake.homeConfigurations.juliendauliac.activation-script.all} $out
          '';
        };
        homeManagerDauliac = pkgs.stdenv.mkDerivation {
          name = "home-manager-system";
          buildCommand = ''
            cp -r ${builtins.head cfg.flake.homeConfigurations.dauliac.activation-script.all} $out
          '';
        };
        systemML-PF59GCGW = pkgs.stdenv.mkDerivation {
          name = "home-manager-system";
          buildCommand = ''
            cp -r ${builtins.head cfg.flake.systemConfigs.ML-PF59GCGW.config.build.toplevel.all} $out
          '';
        };
        default = config.packages.nixos;
      };
    };
}
