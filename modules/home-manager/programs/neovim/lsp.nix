{
  flake.modules.homeManager.neovim-lsp = {
    programs.nixvim = {
      lsp.inlayHints.enable = true;
      plugins.lsp = {
        enable = true;
        inlayHints = true;
        keymaps = {
          silent = true;
          lspBuf = {
            "gd" = "definition";
            "gD" = "declaration";
            "gi" = "implementation";
            "gr" = "references";
            "K" = "hover";
            "<C-k>" = "signature_help";
            "<space>wa" = "add_workspace_folder";
            "<space>wr" = "remove_workspace_folder";
            "<space>D" = "type_definition";
            "<space>rn" = "rename";
            "<space>ca" = "code_action";
          };
          diagnostic = {
            "<space>e" = "open_float";
            "[d" = "goto_prev";
            "]d" = "goto_next";
            "<space>q" = "setloclist";
          };
        };
      };
    };
  };
}
