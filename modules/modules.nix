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
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          lanzaboote.nixosModules.lanzaboote
          catppuccin.nixosModules.catppuccin
          comin.nixosModules.comin
          nix-flatpak.nixosModules.nix-flatpak
        ]
        ++ [
          ./nixos/configuration.nix
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
          nix-index-db.hmModules.nix-index
          sops-nix.homeManagerModules.sops
          catppuccin.homeManagerModules.catppuccin
          nixvim.homeManagerModules.nixvim
          hyprpanel.homeManagerModules.hyprpanel
          nix-flatpak.homeManagerModules.nix-flatpak
        ]
        ++ [
          ./home-manager/home.nix
        ];
    };
    nixpkgsConfig = mkOption {
      description = mdDoc "NixPkgs config to import";
      default = {
        config = {
          allowUnfree = true;
          allowBroken = true;
        };
        overlays = with inputs; [
          hyprpanel.overlay
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
        // config.nixpkgsConfig;
    };
}
