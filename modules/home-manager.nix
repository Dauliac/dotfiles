{
  inputs,
  config,
  ...
}:
let
  inherit (inputs.home-manager.lib) homeManagerConfiguration;
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  userOne = "dauliac";
  userTwo = "juliendauliac";
in
{
  flake.homeConfigurations.${userOne} = homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = { inherit inputs; };
    modules = config.homeManagerModules ++ [
      {
        nixpkgs = config.nixpkgsConfig;
      }
      ./home-manager/profiles/${userOne}
      {
        home.username = userOne;
        home.homeDirectory = "/home/${userOne}/";
      }
    ];
  };
  flake.homeConfigurations.${userTwo} = homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = { inherit inputs; };
    modules = config.homeManagerModules ++ [
      {
        nixpkgs = {
          # TODO: Fix unfree config
          # inherit (config.nixpkgsConfig) config;
          config = {
            allowUnfree = true;
            # allowBroken = true;
          };
          overlays = config.nixpkgsConfig.overlays ++ (with inputs; [ nixGL.overlay ]);
        };
      }
      ./home-manager/profiles/${userTwo}
      {
        home.username = userTwo;
        home.homeDirectory = "/home/${userTwo}/";
      }
    ];
  };
}
