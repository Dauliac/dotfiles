{
  flake.modules.nixvim.ui =
    _:
    let
      luaDir = ./lua;
    in
    {
      colorschemes.catppuccin = {
        enable = true;
        settings = {
          flavour = "mocha";
          transparent_background = true;
        };
      };
      plugins = {
        barbar.enable = true;
        lualine = {
          enable = true;
          settings.sections = {
            lualine_b = [ "branch" "diff" { __unkeyed-1 = "diagnostics"; sources = [ "nvim_lsp" ]; } ];
            lualine_c = [ { __unkeyed-1 = "filename"; path = 1; } "navic" ];
          };
        };
        indent-blankline.enable = true;
        noice.enable = true;
        notify = {
          enable = true;
          settings.background_colour = "#000000";
        };
        web-devicons.enable = true;
        modicator.enable = true;
        neoscroll.enable = true;
        which-key = {
          enable = true;
          settings.spec = [
            { __unkeyed-1 = "<leader>f"; group = "find (fzf)"; }
            { __unkeyed-1 = "<leader>h"; group = "git hunks"; }
            { __unkeyed-1 = "<leader>s"; group = "search / sops"; }
            { __unkeyed-1 = "<leader>x"; group = "trouble"; }
            { __unkeyed-1 = "<leader>w"; group = "workspace"; }
          ];
        };
        nui.enable = true;
        image.enable = true;
        diagram.enable = true;
      };
      extraConfigLua = ''
        dofile("${luaDir}/catppuccin.lua")
      '';
    };
}
