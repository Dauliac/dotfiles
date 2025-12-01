{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mdDoc mkOption;
in
{
  options = {
    nixOsModules = mkOption {
      description = mdDoc "Nixos modules to import";
      default =
        with inputs;
        [
          catppuccin.nixosModules.catppuccin
          comin.nixosModules.comin
          home-manager.nixosModules.home-manager
          #lanzaboote.nixosModules.lanzaboote
          nix-flatpak.nixosModules.nix-flatpak
          nur.modules.nixos.default
          sops-nix.nixosModules.sops
        ]
        ++ [
          ./nixos
          {
            nixpkgs = config.nixpkgsConfig;
            home-manager = {
              useGlobalPkgs = true;
              sharedModules = config.homeManagerModules;
              extraSpecialArgs = { inherit inputs; };
            };
          }
        ];
    };
    homeManagerModules = mkOption {
      description = mdDoc "Home manager modules to import";
      default =
        with inputs;
        [
          nix-index-db.homeModules.nix-index
          sops-nix.homeManagerModules.sops
          catppuccin.homeModules.catppuccin
          nixvim.homeModules.nixvim
          # hyprpanel.homeManagerModules.hyprpanel
          nix-flatpak.homeManagerModules.nix-flatpak
          betterfox-nix.modules.homeManager.betterfox
        ]
        ++ [
          ./home-manager
        ];
    };
    nixpkgsConfig = mkOption {
      description = mdDoc "NixPkgs config to import";
      default = {
        config = {
          allowUnfree = true;
          # allowBroken = true;
        };
        overlays = [
        ];
      };
    };
  };
  config.perSystem =
    { system, ... }:
    {
      _module.args.pkgs =
        import inputs.nixpkgs {
          inherit system;
        }
        // {
          inherit (config.nixpkgsConfig) config;
          overlays = config.nixpkgsConfig.overlays ++ [
            inputs.nixGL.overlay
          ];
        };
    };
}
