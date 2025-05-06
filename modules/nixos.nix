{
  inputs,
  config,
  ...
}:
{
  flake.nixosConfigurations = {
    nixos = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = config.nixOsModules ++ [
        ./nixos/profiles/dauliac
      ];
    };
    manomano = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = config.nixOsModules ++ [
        ./nixos/juliendauliac
      ];
    };
  };
}
