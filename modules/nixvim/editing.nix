{
  flake.modules.nixvim.editing =
    { pkgs, ... }:
    let
      luaDir = ./lua;
    in
    {
      plugins = {
        comment.enable = true;
        nvim-autopairs.enable = true;
        vim-surround.enable = true;
        trim.enable = true;
        yanky.enable = true;
        undotree.enable = true;
        goyo.enable = true;
        ccc.enable = true;
        glow.enable = true;
      };
      extraPlugins = with pkgs.vimPlugins; [
        ssr-nvim
        substitute-nvim
        nvim-sops
      ];
      extraConfigLua = ''
        dofile("${luaDir}/sops.lua")
      '';
    };
}
