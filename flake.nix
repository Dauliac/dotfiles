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

  outputs =
    { nixpkgs
    , home-manager
    , ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      formatterPackages = with pkgs; [
        go-task
        nixpkgs-fmt
        alejandra
        statix
        shfmt
      ];
      checkPackages = with pkgs; [
        go-task
        shellcheck
        typos
        yamllint
      ];
      ciPackages = with pkgs; formatterPackages ++ checkPackages;
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
      devShells.x86_64-linux.default =
        pkgs.mkShell
          {
            # inputsFrom = builtins.attrValues self.checks.${system};
            nativeBuildInputs = with pkgs;
              [
                lefthook
              ]
              ++ ciPackages;

            devShellHook = ''
              task install
            '';
          };
    };
}
