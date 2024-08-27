if vim.g.started_by_firenvim == false then
  local null_ls = require("null-ls")

  local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

  null_ls.setup({
    on_attach = function(client, bufnr)
      if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = augroup,
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ async = false })
          end,
        })
      end
    end,
    sources = {
      null_ls.builtins.completion.spell,
      null_ls.builtins.code_actions.gitsigns,
      null_ls.builtins.code_actions.gomodifytags,
      null_ls.builtins.code_actions.impl,
      null_ls.builtins.code_actions.shellcheck,
      null_ls.builtins.diagnostics.dotenv_linter,
      null_ls.builtins.diagnostics.typos,
      null_ls.builtins.diagnostics.eslint,
      null_ls.builtins.diagnostics.phpcs,
      null_ls.builtins.diagnostics.hadolint,
      null_ls.builtins.diagnostics.phpstan,
      -- null_ls.builtins.diagnostics.editorconfig_checker,
      null_ls.builtins.formatting.black,
      null_ls.builtins.diagnostics.dotenv_linter,
      -- null_ls.builtins.formatting.prettier,
      null_ls.builtins.formatting.stylua,
      null_ls.builtins.formatting.shfmt,
      null_ls.builtins.formatting.sql_formatter,
      null_ls.builtins.formatting.terraform_fmt,
      -- null_ls.builtins.formatting.yamlfix,
      null_ls.builtins.formatting.alejandra,
      null_ls.builtins.formatting.statix,
      null_ls.builtins.formatting.shellharden,
      null_ls.builtins.hover.printenv,
      null_ls.builtins.code_actions.statix,
    },
  })
end
