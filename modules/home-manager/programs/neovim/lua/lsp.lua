require("lspconfig").pyright.setup({
	capabilities = capabilities,
	-- on_attach = require("lsp-format").on_attach,
})

require("lspconfig").terraformls.setup({
	capabilities = capabilities,
	-- on_attach = require("lsp-format").on_attach,
	root_dir = require("lspconfig.util").root_pattern(".git"),
})

require("lspconfig").dockerls.setup({
	capabilities = capabilities,
	-- on_attach = require("lsp-format").on_attach,
	settings = {
		docker = {
			languageserver = {
				formatter = {
					ignoreMultilineInstructions = true,
				},
			},
		},
	},
})

require("lspconfig").gopls.setup({
	capabilities = capabilities,
	-- on_attach = require("lsp-format").on_attach,
})

require("lspconfig").nil_ls.setup({
	capabilities = capabilities,
	settings = {
		["nil"] = {
			formatting = {
				command = { "nixpkgs-fmt" },
			},
		},
	},
})

require("lspconfig").eslint.setup({
	capabilities = capabilities,
	-- on_attach = require("lsp-format").on_attach,
})

require("lspconfig").lua_ls.setup({
	capabilities = capabilities,
	-- on_attach = require("lsp-format").on_attach,
})

require("lspconfig").yamlls.setup({
	capabilities = capabilities,
	-- on_attach = require("lsp-format").on_attach,
	settings = {
		yaml = {
			format = {
				bracketSpacing = false,
				enable = true,
			},
			customTags = { "!reference sequence" },
			schemas = {
				["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/all.json"] = "k8s/**/*.yml",
				["https://taskfile.dev/schema.json"] = "**/Taskfile.*",
				["https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"] = {
					".gitlab-ci.yml",
					"ci/environments/**/*.yaml",
					"ci/modules/**/*.yaml",
				},
				["https://json.schemastore.org/container-structure-test.json"] = ".cst.yml",
			},
			editor = {
				formatOnType = true,
				tabSize = 2,
			},
		},
	},
})

--[[ require("lsp-format").setup {
    typescript = {
      tab_width = function()
        return vim.opt.shiftwidth:get()
      end,
    },
    javascript = { tab_width = 2 },
    vue = { tab_width = 2 },
  } ]]

local prettier = {
	formatCommand = [[prettier --stdin-filepath ''${INPUT} ''${--tab-width:tab_width}]],
	formatStdin = true,
}

require("lspconfig").volar.setup({
	filetypes = {
		"javascript",
		"json",
		"vue",
	},
	capabilities = capabilities,
	-- on_attach = require("lsp-format").on_attach,
	init_options = {
		typescript = {
			tsdk = "${pkgs.nodePackages.typescript}/lib/node_modules/typescript/lib",
		},
	},
	settings = {
		languages = {
			javascript = { prettier },
			typescript = { prettier },
			vue = { prettier },
		},
	},
})

vim.g.rustaceanvim = {
	tools = {
		runnables = {
			use_telescope = true,
		},
		inlay_hints = {
			auto = true,
			show_parameter_hints = false,
			parameter_hints_prefix = "",
			other_hints_prefix = "",
		},
	},
	server = {
		on_attach = function(client, bufnr)
			require("lsp-format").on_attach(client, bufnr)
			-- vim.lsp.inlay_hint.enable(0, true)
		end,
		capabilities = capabilities,
		root_pattern = { "Cargo.toml", "Cargo.lock" },
		-- cmd = { "direnv", "exec", ".", "rust-analyzer" },
		filetypes = { "rust" },
		settings = {
			["rust-analyzer"] = {
				checkOnSave = {
					command = "clippy",
				},
			},
		},
	},
}

require("lspconfig").phpactor.setup({
	capabilities = capabilities,
})

require("lspconfig").markdown_oxide.setup({
	capabilities = capabilities,
	-- on_attach = require("lsp-format").on_attach,
})
