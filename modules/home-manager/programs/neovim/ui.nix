{
  flake.modules.homeManager.neovim-ui =
    { pkgs, ... }:
    let
      luaDir = ./lua;
    in
    {
      programs.nixvim = {
        colorschemes.catppuccin.enable = true;
        plugins = {
          barbar.enable = true;
          lualine.enable = true;
          indent-blankline.enable = true;
          noice.enable = true;
          web-devicons.enable = true;
          modicator.enable = true;
          neoscroll.enable = true;
          which-key.enable = true;
          nui.enable = true;
          image.enable = true;
          diagram.enable = true;
        };
        extraConfigLua = ''
          dofile("${luaDir}/catppuccin.lua")
        '';
      };
    };
}
