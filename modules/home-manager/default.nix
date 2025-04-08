{
  inputs,
  config,
  ...
}:
let
  inherit (inputs.home-manager.lib) homeManagerConfiguration;
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  userOne = "jdauliac";
  userTwo = "juliendauliac";
in
{
  flake.homeConfigurations.${userOne} = homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = { inherit inputs; };
    modules = config.homeManagerModules ++ [
      {
        nixpkgs = {
          inherit (config.nixpkgsConfig) config;
          overlays = [ inputs.nixGL.overlay ];
        };
      }
      ./profiles/${userOne}.nix
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
          inherit (config.nixpkgsConfig) config;
          overlays = [ inputs.nixGL.overlay ];
        };
      }
      ./profiles/${userTwo}.nix
      {
        home.username = userTwo;
        home.homeDirectory = "/home/${userTwo}/";
      }
    ];
  };
}
