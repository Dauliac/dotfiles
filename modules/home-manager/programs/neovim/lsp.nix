{ ... }:
{
  programs.nixvim = {

    lsp = {
      inlayHints = {
        enable = true;
      };

      servers = {
        gopls = {
          enable = true;
          settings = {
            gopls = {
              analyses.unusedparams = true;
              staticcheck = true;
              gofumpt = true;
            };
          };
        };

        lua_ls = {
          enable = true;
          settings = {
            Lua = {
              diagnostics.globals = [ "vim" ];
            };
          };
        };

        bashls.enable = true;
        clangd.enable = true;
        cmake.enable = true;
        cssls.enable = true;
        cue.enable = true;
        docker_compose_language_service.enable = true;
        dockerls.enable = true;
        eslint.enable = true;
        helm_ls.enable = true;
        html.enable = true;
        jsonls.enable = true;
        just.enable = true;
        nil_ls.enable = true;
        nixd.enable = true;
        pyright.enable = true;
        tailwindcss.enable = true;
        taplo.enable = true;
        terraformls.enable = true;
        ts_ls.enable = true;
        typos_lsp.enable = true;
        yamlls.enable = true;
      };
    };

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
}
