{
  inputs,
  config,
  ...
}:
{
  config = {
    flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = config.nixOsModules;
    };
  };
}
