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
            touch $out
          '';
        };
        homeManagerDauliac = pkgs.stdenv.mkDerivation {
          name = "home-manager-system";
          buildCommand = ''
            cp -r ${builtins.head cfg.flake.homeConfigurations.dauliac.activation-script.all} $out
            # touch $out
          '';
        };
        default = config.packages.nixos;
      };
    };
}
