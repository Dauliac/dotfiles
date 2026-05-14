{ inputs, ... }:
{
  flake.modules.homeManager.neovim-lang-devops =
    { pkgs, ... }:
    let
      yaml-companion-nvim = pkgs.vimUtils.buildVimPlugin {
        name = "yaml-companion-nvim";
        src = "${inputs.yaml-companion-nvim.outPath}";
        doCheck = false;
      };
    in
    {
      programs.nixvim = {
        plugins.treesitter.grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          dockerfile
          hcl
          json
          terraform
          toml
          xml
          yaml
        ];
        lsp.servers = {
          dockerls.enable = true;
          docker_compose_language_service.enable = true;
          helm_ls.enable = true;
          jsonls.enable = true;
          taplo.enable = true;
          terraformls.enable = true;
          yamlls.enable = true;
        };
        extraPlugins = with pkgs.vimPlugins; [
          vim-helm
          yaml-companion-nvim
        ];
      };
    };
}
