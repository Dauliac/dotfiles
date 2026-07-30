{
  flake.modules.nixvim.lang-go =
    { pkgs, ... }:
    {
      plugins = {
        treesitter.grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          go
          gomod
          gosum
        ];
        dap-go.enable = true;
        neotest.adapters.go.enable = true;
      };
      lsp.servers.gopls = {
        enable = true;
        config.gopls = {
          analyses.unusedparams = true;
          staticcheck = true;
          gofumpt = true;
        };
      };
    };
}
