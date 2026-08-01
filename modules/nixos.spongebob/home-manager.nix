{ inputs, ... }: {
  flake.modules.nixos.spongebob-home-manager = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      users.dauliac.imports = [ inputs.self.modules.homeManager.user-dauliac ];
    };
  };
}
