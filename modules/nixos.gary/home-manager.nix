{ inputs, ... }: {
  flake.modules.nixos.gary-home-manager = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      users.gary.imports = [ inputs.self.modules.homeManager.user-gary ];
      users.dauliac.imports = [ inputs.self.modules.homeManager.user-dauliac ];
    };
  };
}
