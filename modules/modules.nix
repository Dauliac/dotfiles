{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mdDoc mkOption;
  cfg = config;
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
          musnix.nixosModules.musnix
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
        # overlays = [
        #   inputs.foo.overlays.default
        #   (final: prev: {
        #     # ... things you need to patch ...
        #   })
        # ];
      };
    };
  };
  config.perSystem =
    {
      config,
      system,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        inherit (cfg.nixpkgsConfig) config;
      };
    };
}
