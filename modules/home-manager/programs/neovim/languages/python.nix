{
  flake.modules.homeManager.neovim-lang-python =
    { pkgs, ... }:
    {
      programs.nixvim = {
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
    };
}
