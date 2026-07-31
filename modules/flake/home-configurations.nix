{
  config,
  inputs,
  lib,
  ...
}:
let
  system = "x86_64-linux";

  pkgs = import inputs.nixpkgs {
    inherit system;
    inherit (config.dotfiles) overlays;
    config = config.dotfiles.nixpkgsConfig;
  };

  mkUser =
    username:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        inputs.nlib.homeModules.default
        config.flake.modules.homeManager."user-${username}"
        {
          home = {
            inherit username;
            homeDirectory = "/home/${username}";
          };
        }
      ];
    };

  users = [
    "dauliac"
    "juliendauliac"
  ];
in
{
  flake.homeConfigurations = lib.genAttrs users mkUser;
}
