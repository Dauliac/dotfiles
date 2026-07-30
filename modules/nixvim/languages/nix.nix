{
  flake.modules.nixvim.lang-nix =
    { pkgs, ... }:
    {
      plugins.treesitter.grammarPackages = [
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.nix
      ];
      lsp.servers = {
        nil_ls = {
          enable = true;
          config.nil.diagnostics.ignored = [
            "unused_binding"
            "unused_with"
          ];
        };
        nixd = {
          enable = true;
          config.nixd = {
            nixpkgs.expr = "import (builtins.getFlake \"nixpkgs\") { system = \"x86_64-linux\"; }";
            formatting.command = [ "nixfmt" ];
            options = {
              nixos.expr = "(builtins.getFlake \"nixpkgs\").lib.nixosSystem { system = \"x86_64-linux\"; modules = []; }.options";
              home-manager.expr = "(builtins.getFlake \"home-manager\").lib.homeManagerConfiguration { pkgs = import (builtins.getFlake \"nixpkgs\") { system = \"x86_64-linux\"; }; modules = []; }.options";
              flake-parts.expr = "let flake-parts = builtins.getFlake \"flake-parts\"; in flake-parts.lib.mkFlake { inputs = { self = {}; }; } { systems = []; imports = [ flake-parts.flakeModules.flakeModules ]; }";
            };
            diagnostic.suppress = [ "sema-extra-with" ];
          };
        };
      };
    };
}
