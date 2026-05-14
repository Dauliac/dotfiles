{
  flake.modules.homeManager.neovim-dap =
    { pkgs, ... }:
    let
      luaDir = ./lua;
    in
    {
      programs.nixvim = {
        plugins = {
          dap.enable = true;
          dap-rr.enable = true;
          dap-ui.enable = true;
          dap-virtual-text.enable = true;
          neotest.enable = true;
        };
        extraPlugins = [
          pkgs.vimPlugins.lazydev-nvim
        ];
        extraConfigLua = ''
          require("lazydev").setup({
            library = {
              { path = "${pkgs.vimPlugins.nvim-dap-ui}", words = { "dapui" } },
            },
          })
          dofile("${luaDir}/dap.lua")
        '';
      };
    };
}
