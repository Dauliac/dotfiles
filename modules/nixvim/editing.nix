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
        nvim-surround.enable = true;
        trim.enable = true;
        yanky.enable = true;
        undotree.enable = true;
        goyo.enable = true;
        ccc.enable = true;
        glow.enable = true;
      };
      keymaps = [
        { mode = "n"; key = "<leader>u"; action = "<Cmd>UndotreeToggle<CR>"; options.desc = "Toggle Undotree"; }
        { mode = "n"; key = "<leader>z"; action = "<Cmd>Goyo<CR>"; options.desc = "Toggle Goyo zen mode"; }
        { mode = "n"; key = "<leader>se"; action = "<Cmd>SopsEncrypt<CR>"; options.desc = "Sops: encrypt file"; }
        { mode = "n"; key = "<leader>sd"; action = "<Cmd>SopsDecrypt<CR>"; options.desc = "Sops: decrypt file"; }
      ];
      extraPlugins = with pkgs.vimPlugins; [
        nvim-sops
      ];
      extraConfigLua = ''
        dofile("${luaDir}/sops.lua")
      '';
    };
}
