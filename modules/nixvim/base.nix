{
  flake.modules.nixvim.base =
    { pkgs, ... }:
    {
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      globals.mapleader = ",";
      clipboard = {
        register = "unnamedplus";
        providers.wl-copy.enable = true;
      };
      plugins = {
        distant.enable = true;
        treesitter = {
          enable = true;
          settings = {
            highlight.enable = true;
            indent.enable = true;
            incremental_selection = {
              enable = true;
              keymaps = {
                init_selection = "<C-space>";
                node_incremental = "<C-space>";
                scope_incremental = false;
                node_decremental = "<bs>";
              };
            };
          };
          grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
            markdown
            markdown_inline
            vim
            vimdoc
          ];
        };
      };
      extraPlugins = [
        pkgs.vimPlugins.plenary-nvim
      ];
    };
}
