---
require("crates").setup()

local capabilities = require("cmp_nvim_lsp").default_capabilities()

capabilities.workspace = {
    didChangeWatchedFiles = {
      dynamicRegistration = true,
    },
}

require("lspconfig").pyright.setup({
	capabilities = capabilities,
	-- on_attach = require("lsp-format").on_attach,
})

require("lspconfig").terraformls.setup({
	capabilities = capabilities,
  filetypes = { "tf", "hcl"},
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

local yaml_cfg = require("yaml-companion").setup({
  builtin_matchers = {
    kubernetes = { enabled = true },
    cloud_init = { enabled = true },
  },
  schemas = {
    {
      name = "kubernetes 1.22.4",
      uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.22.4-standalone-strict/all.json",
    },
    {
      name = "container structure test",
      uri = "https://json.schemastore.org/container-structure-test.json",
    },
    {
      name = "taskfile",
      uri = "https://taskfile.dev/schema.json",
    },
    {
      name = "flux gitRepository",
      uri = "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/gitrepository-source-v1.json",
    },
    {
      name = "flux helmRelease",
      uri = "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/gitrepository-source-v1.json",
    },
    {
      name = "kustomization",
      uri = "https://json.schemastore.org/kustomization.json"
    },
  },
  lspconfig = {
    settings = {
      yaml = {
        validate = true,
        schemaStore = {
          enable = false,
          url = "",
        },
        -- schemas = require('schemastore').yaml.schemas {
        --   select = {
        --     'kustomization.yaml',
        --     'GitHub Workflow',
        --     'chart',
        --     'Taskfile config',
        --     'gitlab-ci',
        --   }
        -- }
      }
    }
  }
})


-- require("lspconfig").yamlls.setup(yaml_cfg)

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
			local il_hints = require("lsp-inlayhints")
			il_hints.on_attach(client, bufnr)
		end,
		capabilities = capabilities,
		root_pattern = { "Cargo.toml", "Cargo.lock" },
		filetypes = { "rust" },
		inlay_hints = {
			highlight = "NonText",
		},
		tools = {
			hover_actions = {
				auto_focus = true,
			},
		},
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
	on_attach = require("lsp-format").on_attach,
})

require'lspconfig'.helm_ls.setup{}
