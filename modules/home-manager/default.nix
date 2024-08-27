{
  inputs,
  ...
}: let
  inherit (inputs.home-manager.lib) homeManagerConfiguration;
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  shared = [
    inputs.nix-index-db.hmModules.nix-index
    inputs.sops-nix.homeManagerModules.sops
    inputs.catppuccin.homeManagerModules.catppuccin
    inputs.nixvim.homeManagerModules.nixvim
    ./home.nix
  ];
  userOne = "jdauliac";
  userTwo = "dauliac";
in {
  flake.homeConfigurations.${userOne} = homeManagerConfiguration {
    inherit pkgs;
    modules =
      shared
      ++ [
        {nixpkgs.overlays = [inputs.nixGL.overlay];}
        ./profiles/${userOne}.nix
        {
          home.username = userOne;
          home.homeDirectory = "/home/${userOne}/";
        }
      ];
    extraSpecialArgs = {inherit inputs;};
  };
  flake.homeConfigurations.${userTwo} = homeManagerConfiguration {
    inherit pkgs;
    modules =
      shared
      ++ [
        ./profiles/${userTwo}.nix
        {
          home.username = userTwo;
          home.homeDirectory = "/home/${userTwo}/";
        }
      ];
    extraSpecialArgs = {inherit inputs;};
  };
}
