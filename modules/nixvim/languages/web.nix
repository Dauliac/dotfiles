{
  flake.modules.nixvim.lang-web =
    { pkgs, ... }:
    {
      plugins.treesitter.grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        css
        html
      ];
      lsp.servers = {
        html.enable = true;
        cssls.enable = true;
      };
    };
}
