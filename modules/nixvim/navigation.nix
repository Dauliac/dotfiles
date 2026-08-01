{ inputs, ... }: {
  flake.modules.nixvim.navigation =
    { pkgs, ... }:
    let
      commander-nvim = pkgs.vimUtils.buildVimPlugin {
        name = "commander";
        src = "${inputs.commander-nvim.outPath}";
        doCheck = false;
      };
      luaDir = ./lua;
    in
    {
      plugins = {
        telescope = {
          enable = true;
          extensions.fzf-native.enable = true;
        };
        fzf-lua.enable = true;
        flash.enable = true;
        spider.enable = true;
        spectre.enable = true;
        yazi.enable = true;
      };
      extraPlugins = with pkgs.vimPlugins; [
        commander-nvim
        nvim-hlslens
      ];
      extraConfigLua = ''
        dofile("${luaDir}/commander.lua")
        dofile("${luaDir}/fzf.lua")
      '';
    };
}
