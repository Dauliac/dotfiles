{
  flake.modules.nixvim.lang-shell = { pkgs, ... }: {
    plugins = {
      treesitter.grammarPackages = [
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.bash
      ];
      neotest.adapters.bash.enable = true;
    };
    lsp.servers.bashls.enable = true;
  };
}
