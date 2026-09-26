{
  flake.modules.nixvim.lang-devops =
    { pkgs, ... }:
    {
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
        jsonls = {
          enable = true;
          config.json = {
            schemas = [
              { fileMatch = [ "package.json" ]; url = "https://json.schemastore.org/package.json"; }
              { fileMatch = [ "tsconfig*.json" ]; url = "https://json.schemastore.org/tsconfig.json"; }
              { fileMatch = [ ".prettierrc" ".prettierrc.json" ]; url = "https://json.schemastore.org/prettierrc.json"; }
              { fileMatch = [ ".eslintrc" ".eslintrc.json" ]; url = "https://json.schemastore.org/eslintrc.json"; }
              { fileMatch = [ "*.code-workspace" ]; url = "https://json.schemastore.org/vscode-workspace.json"; }
            ];
            validate.enable = true;
          };
        };
        taplo.enable = true;
        terraformls.enable = true;
        yamlls = {
          enable = true;
          config.yaml = {
            schemas = {
              "https://json.schemastore.org/github-workflow.json" = "/.github/workflows/*";
              "https://json.schemastore.org/github-action.json" = "/.github/actions/*/action.{yml,yaml}";
              "https://json.schemastore.org/docker-compose.json" = [ "docker-compose*.yml" "docker-compose*.yaml" "compose.yml" "compose.yaml" ];
              "https://json.schemastore.org/kustomization.json" = "kustomization.{yml,yaml}";
              "https://json.schemastore.org/pre-commit-config.json" = ".pre-commit-config.{yml,yaml}";
              "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json" = [ "openapi.{yml,yaml}" "*openapi*.{yml,yaml}" ];
            };
            validate = true;
            hover = true;
            completion = true;
          };
        };
      };
      extraPlugins = with pkgs.vimPlugins; [
        vim-helm
      ];
    };
}
