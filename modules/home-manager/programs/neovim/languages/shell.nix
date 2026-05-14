{
  flake.modules.homeManager.neovim-lang-shell =
    { pkgs, ... }:
    {
      programs.nixvim = {
        plugins = {
          treesitter.grammarPackages = [
            pkgs.vimPlugins.nvim-treesitter.builtGrammars.bash
          ];
          neotest.adapters.bash.enable = true;
        };
        lsp.servers.bashls.enable = true;
      };
    };
}
