{
  flake.modules.homeManager.neovim-lang-lua =
    { pkgs, ... }:
    {
      programs.nixvim = {
        plugins.treesitter.grammarPackages = [
          pkgs.vimPlugins.nvim-treesitter.builtGrammars.lua
        ];
        lsp.servers.lua_ls = {
          enable = true;
          config.Lua.diagnostics.globals = [ "vim" ];
        };
      };
    };
}
