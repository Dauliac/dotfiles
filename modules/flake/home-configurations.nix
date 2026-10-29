{
  config,
  inputs,
  lib,
  ...
}:
let
  system = "x86_64-linux";

  pkgs = import inputs.nixpkgs {
    inherit system;
    inherit (config.dotfiles) overlays;
    config = config.dotfiles.nixpkgsConfig;
  };

  mkUser =
    username:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        # inputs.nlib.homeModules.default is pulled in transitively by
        # xi.homeManagerModules.default (see modules/home-manager/programs/xi.nix).
        # Importing it directly here duplicates the nix-lib adapter and
        # raises "option `nix-lib.lib' is already declared", mirroring the
        # NixOS-side fix in modules/flake/nixos-configurations.nix (889b571).
        config.flake.modules.homeManager."user-${username}"
        # Break the home-manager + nixvim recursion in nlib's HM adapter:
        # the adapter extracts `config.programs.nixvim.nix-lib.fns`, which
        # forces nixvim's submodule eval, which resolves its `lib` arg from
        # the outer `config.lib`, which is itself defined in terms of the
        # extracted nestedLibs. Infinite recursion.
        # Fixed upstream in Dauliac/nlib with the `nix-lib.scanNestedSystems`
        # opt-out (see mkAdapter.nix). We flip it off here because this HM
        # config pairs nixvim with the standalone HM adapter and doesn't rely
        # on `config.lib.vim.*`.
        { nix-lib.scanNestedSystems = false; }
        {
          home = {
            inherit username;
            homeDirectory = "/home/${username}";
          };
        }
      ];
    };

  users = [
    "dauliac"
    "juliendauliac"
  ];
in
{
  flake.homeConfigurations = lib.genAttrs users mkUser;
}
