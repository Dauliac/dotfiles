{
  description = "Dauliac Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , flake-utils
    ,
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};

      formatterPackages = with pkgs; [
        nixpkgs-fmt
        alejandra
        statix
      ];

      makeHomeManagerConfiguration =
        { system
        , username
        , homeDirectory ? "/Users/${username}"
        ,
        }:
        let
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ./home.nix
            {
              home = {
                inherit homeDirectory username;
                stateVersion = "23.11";
              };
            }
          ];
        };
    in
    {
      homeConfigurations = {
        "dauliac" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          modules = [ ./home.nix ];
        };
      };

      packages = rec {
        nvim = pkgs.neovimDauliac;
        default = home-manager.defaultPackage.${system};
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

      checks = {
        typos = pkgs.mkShell {
          buildInputs = with pkgs; [ typos ];
          shellHook = ''
            typos .
          '';
        };
        yamllint = pkgs.mkShell {
          buildInputs = with pkgs; [ yamllint ];
          shellHook = ''
            yamllint .
          '';
        };
        luaCheck = pkgs.mkShell {
          buildInputs = with pkgs; [ luaPackages.luacheck ];
          shellHook = ''
            luacheck . --globals vim feedkey
          '';
        };
      };

      devShells.default =
        pkgs.mkShell
          {
            inputsFrom = builtins.attrValues self.checks.${system};
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
    });
}
