{
  flake.modules.homeManager.neovim-lang-misc =
    { pkgs, ... }:
    {
      programs.nixvim = {
        plugins.treesitter.grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          cue
          just
          make
          regex
        ];
        lsp.servers = {
          clangd.enable = true;
          cmake.enable = true;
          cue.enable = true;
          just.enable = true;
          typos_lsp.enable = true;
        };
      };
    };
}
