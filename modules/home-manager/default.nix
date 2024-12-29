{
  inputs,
  config,
  ...
}:
let
  inherit (inputs.home-manager.lib) homeManagerConfiguration;
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  userOne = "jdauliac";
in
{
  flake.homeConfigurations.${userOne} = homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = { inherit inputs; };
    modules = config.homeManagerModules ++ [
      { nixpkgs.overlays = [ inputs.nixGL.overlay ]; }
      ./profiles/${userOne}.nix
      {
        home.username = userOne;
        home.homeDirectory = "/home/${userOne}/";
      }
    ];
  };
}
