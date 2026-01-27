{
  inputs,
  config,
  ...
}:
let
  system = "x86_64-linux";
in
{
  flake.nixosConfigurations = {
    gary = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = config.nixOsModules ++ [
        { nixpkgs.hostPlatform = system; }
        ./nixos/profiles/gary
      ];
    };
    spongebob = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = config.nixOsModules ++ [
        { nixpkgs.hostPlatform = system; }
        ./nixos/profiles/spongebob
      ];
    };
  };
}
