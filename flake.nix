{
  description = "Home Manager configuration of dauliac";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixGL = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, nixGL, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [ "parsec-bin" ];
        };
      };
      # pkgs = nixpkgs.legacyPackages.${system};
      formatterPackages = with pkgs; [
        go-task
        nixpkgs-fmt
        alejandra
        statix
        shfmt
      ];
      checkPackages = with pkgs; [ go-task shellcheck typos yamllint ];
      ciPackages = with pkgs; formatterPackages ++ checkPackages;
    in
    {
      homeConfigurations."jdauliac" =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            { nixpkgs.overlays = [ nixGL.overlay ]; }
            ./modules/users/jdauliac.nix
          ];
          extraSpecialArgs = { inherit inputs; };
        };

      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;

      homeConfigurations."dauliac" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          { nixpkgs.overlays = [ nixGL.overlay ]; }
          ./modules/users/dauliac.nix
        ];
        extraSpecialArgs = { inherit inputs; };
      };

      formatter = pkgs.writeShellApplication {
        name = "normalise_nix";
        runtimeInputs = formatterPackages;
        text = ''
          task format
        '';
      };

      checks = {
        check = pkgs.mkShell {
          buildInputs = with pkgs; checkPackages;
          shellHook = ''
            task check
          '';
        };
      };
      nix.experimental.features = "nix-command";
      devShells.x86_64-linux.default = pkgs.mkShell {
        # inputsFrom = builtins.attrValues self.checks.${system};
        nativeBuildInputs = with pkgs; [ lefthook ] ++ ciPackages;

        devShellHook = ''
          task install
        '';
      };
    };
}
