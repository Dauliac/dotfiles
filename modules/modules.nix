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
          ./nixos/disko.nix
          ./nixos/configuration.nix
          ./nixos/home-manager.nix
          {
            home-manager = {
              sharedModules = config.homeManagerModules;
              extraSpecialArgs = { inherit inputs; };
            };
            home-manager.users.dauliac = {
              imports = [
                ./home-manager/profiles/dauliac.nix
              ];
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
