{
  description = "Home Manager configuration of dauliac";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      formatterPackages = with pkgs; [
        nixpkgs-fmt
        alejandra
        statix
      ];
    in
    {
      homeConfigurations."dauliac" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };


      formatter = pkgs.writeShellApplication {
        name = "normalise_nix";
        runtimeInputs = formatterPackages;
        text = ''
          set -o xtrace
          alejandra "$@"
          nixpkgs-fmt "$@"
          statix fix "$@"
        '';
      };

      # checks = {
      #   typos = pkgs.mkShell {
      #     buildInputs = with pkgs; [ typos ];
      #     shellHook = ''
      #       typos .
      #     '';
      #   };
      #   yamllint = pkgs.mkShell {
      #     buildInputs = with pkgs; [ yamllint ];
      #     shellHook = ''
      #       yamllint .
      #     '';
      #   };
      # };

      devShells.x86_64-linux.default =
        pkgs.mkShell
          {
            # inputsFrom = builtins.attrValues self.checks.${system};
            nativeBuildInputs = with pkgs;
              [
                lefthook
                go-task
              ]
              ++ formatterPackages;

            devShellHook = ''
              task install
            '';
          };
    };
}
