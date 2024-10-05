{
  inputs,
  ...
}: {
  config = {
    flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # BUG: Check why this not works
      # nixpkgs.config.allowUnfree = true;
      modules = [
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops
        inputs.lanzaboote.nixosModules.lanzaboote
        ./disko.nix
        ./configuration.nix
        ./hardware-configuration.nix
        ./home-manager.nix
        {
          home-manager = {
            sharedModules = [
              inputs.nix-index-db.hmModules.nix-index
              inputs.sops-nix.homeManagerModules.sops
              inputs.catppuccin.homeManagerModules.catppuccin
              inputs.nixvim.homeManagerModules.nixvim
              ../home-manager/home.nix
            ];
            extraSpecialArgs = {inherit inputs;};
          };
          home-manager.users.dauliac = {
            imports = [
              ../home-manager/profiles/dauliac.nix
            ];
          };
        }
      ];
    };
  };
}
