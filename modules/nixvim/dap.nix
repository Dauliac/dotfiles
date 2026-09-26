{
  flake.modules.nixvim.dap =
    { pkgs, ... }:
    let
      luaDir = ./lua;
    in
    {
      plugins = {
        dap.enable = true;
        dap-rr.enable = true;
        dap-ui.enable = true;
        dap-virtual-text.enable = true;
        neotest.enable = true;
      };
      keymaps = [
        { mode = "n"; key = "<F5>"; action.__raw = "function() require('dap').continue() end"; options.desc = "DAP: continue"; }
        { mode = "n"; key = "<F10>"; action.__raw = "function() require('dap').step_over() end"; options.desc = "DAP: step over"; }
        { mode = "n"; key = "<F11>"; action.__raw = "function() require('dap').step_into() end"; options.desc = "DAP: step into"; }
        { mode = "n"; key = "<F12>"; action.__raw = "function() require('dap').step_out() end"; options.desc = "DAP: step out"; }
        { mode = "n"; key = "<leader>b"; action.__raw = "function() require('dap').toggle_breakpoint() end"; options.desc = "DAP: toggle breakpoint"; }
      ];
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
}
