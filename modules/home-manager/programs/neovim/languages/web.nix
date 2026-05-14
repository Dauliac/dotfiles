{
  flake.modules.homeManager.neovim-lang-web =
    { pkgs, ... }:
    {
      programs.nixvim = {
        plugins.treesitter.grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          css
          html
        ];
        lsp.servers = {
          html.enable = true;
          cssls.enable = true;
        };
      };
    };
}
