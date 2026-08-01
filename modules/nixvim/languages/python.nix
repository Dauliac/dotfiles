{
  flake.modules.nixvim.lang-python = { pkgs, ... }: {
    plugins = {
      treesitter.grammarPackages = [
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.python
      ];
      dap-python.enable = true;
    };
    lsp.servers = {
      pyright.enable = true;
      ruff.enable = true;
    };
  };
}
