{
  inputs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption mdDoc;
  inherit (inputs.flake-parts.lib) mkPerSystemOption;
  inherit (inputs.home-manager.lib) homeManagerConfiguration;
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
in {
  flake.homeConfigurations.jdauliac = homeManagerConfiguration {
    inherit pkgs;
    imports = [
      {nixpkgs.overlays = [inputs.nixGL.overlay];}
      {
        imports = [./home.nix];
        home.username = "jdauliac";
        home.homeDirectory = "/home/jdauliac/";
      }
    ];
    extraSpecialArgs = {inherit inputs;};
  };
  flake.homeConfigurations.dauliac = homeManagerConfiguration {
    inherit pkgs;
    modules = [
      inputs.nix-index-db.hmModules.nix-index
      inputs.sops-nix.homeManagerModules.sops
      ./home.nix
      {
        home.username = "dauliac";
        home.homeDirectory = "/home/dauliac/";
      }
    ];
    extraSpecialArgs = {inherit inputs;};
  };
}
