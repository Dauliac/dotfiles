{
  inputs,
  config,
  ...
}:
{
  flake.nixosConfigurations = {
    gary = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = config.nixOsModules ++ [
        ./nixos/profiles/gary
      ];
    };
    spongebob = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = config.nixOsModules ++ [
        ./nixos/profiles/spongebob
      ];
    };
  };
}
