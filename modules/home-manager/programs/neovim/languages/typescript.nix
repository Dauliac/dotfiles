{
  flake.modules.homeManager.neovim-lang-typescript =
    { pkgs, ... }:
    {
      programs.nixvim = {
        plugins = {
          treesitter.grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
            javascript
            tsx
            typescript
          ];
          neotest.adapters.jest.enable = true;
        };
        lsp.servers = {
          ts_ls.enable = true;
          eslint.enable = true;
          tailwindcss.enable = true;
        };
      };
    };
}
