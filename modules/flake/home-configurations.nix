# Home-manager configurations using flake-parts home-manager module
# The module provides proper merging for homeConfigurations defined across files
{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (inputs.home-manager.lib) homeManagerConfiguration;

  system = "x86_64-linux";

  pkgs = import inputs.nixpkgs {
    inherit system;
    config = config.dotfiles.nixpkgsConfig;
    inherit (config.dotfiles) overlays;
  };

  mkUser =
    username:
    homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs;
        nixGlWrapper = config.lib.nixgl.wrapPackage { inherit pkgs; };
        proprietaryEnabled = config.dotfiles.proprietary.enable;
      };
      modules =
        config.dotfiles.home.externalModules
        ++ config.dotfiles.home.sharedModules
        ++ (config.dotfiles.home.userModules.${username} or [ ])
        ++ [
          {
            nixpkgs.config = config.dotfiles.nixpkgsConfig;
            nixpkgs.overlays = config.dotfiles.overlays;
          }
          {
            home.username = username;
            home.homeDirectory = "/home/${username}";
          }
        ];
    };

  # List of users to generate configurations for
  users = [
    "dauliac"
    "juliendauliac"
  ];
in
{
  # Use flake-parts home-manager module's option for proper merging
  flake.homeConfigurations = lib.genAttrs users mkUser;
}
