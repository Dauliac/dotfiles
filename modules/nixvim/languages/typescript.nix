{
  flake.modules.nixvim.lang-typescript =
    { pkgs, ... }:
    {
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
}
