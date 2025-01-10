---
require("crates").setup()
require("yaml-companion").open_ui_select()

local capabilities = require("cmp_nvim_lsp").default_capabilities()

capabilities.workspace = {
	didChangeWatchedFiles = {
		dynamicRegistration = true,
	},
}

require("lspconfig").bashls.setup({
	capabilities = capabilities,
})

require("lspconfig").pyright.setup({
	capabilities = capabilities,
	-- on_attach = require("lsp-format").on_attach,
})

require("lspconfig").terraformls.setup({
	capabilities = capabilities,
	filetypes = { "tf", "hcl" },
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

require("lspconfig").svelte.setup({
	capabilities = capabilities,
	on_attach = require("lsp-format").on_attach,
})

-- NOTE: YAML variables and Helm LS (quite big!)
local schemas = {}

local kubernetes =
	"https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/v1.29.6-standalone-strict/all.json"
local flux2 = "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/refs/heads/main/all.json"
local gitlab = "https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"
local taskfile = "https://taskfile.dev/schema.json"
local podmonitor =
	"https://raw.githubusercontent.com/datreeio/CRDs-catalog/refs/heads/main/monitoring.coreos.com/podmonitor_v1.json"
local servicemonitor =
	"https://raw.githubusercontent.com/datreeio/CRDs-catalog/refs/heads/main/monitoring.coreos.com/servicemonitor_v1.json"
local prometheus =
	"https://raw.githubusercontent.com/datreeio/CRDs-catalog/refs/heads/main/monitoring.coreos.com/prometheus_v1.json"
local ingress =
	"https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/v1.30.1/ingress-networking-v1.json"
local lefthook = "https://json.schemastore.org/lefthook.json"
local github = "https://json.schemastore.org/github-workflow.json"

schemas[kubernetes] = {
	"templates/*deployment.yaml",
	"templates/*service.yaml",
	"templates/*secret.yaml",
	"templates/*configmap.yaml",
	"templates/*daemonset.yaml",
	"templates/*replicaset.yaml",
	"templates/*persistentvolume.yaml",
	"templates/*persistentvolumeclaim.yaml",
	"templates/*serviceaccount.yaml",
	"templates/*role.yaml",
	"templates/*rolebinding.yaml",
	"templates/*clusterrole.yaml",
	"templates/*clusterrolebinding.yaml",
	"templates/*job*.yaml",
}
schemas[podmonitor] = "templates/*podmonitor*"
schemas[servicemonitor] = "templates/*servicemonitor*"
schemas[ingress] = "templates/*ingress*"

local cfg = require("yaml-companion").setup({
	schemas = {
		{ name = "Flux2", uri = flux2 },
		{ name = "Gitlab", uri = gitlab },
		{ name = "Taskfile", uri = taskfile },
		{ name = "PodMonitor", uri = podmonitor },
		{ name = "ServiceMonitor", uri = servicemonitor },
		{ name = "Prometheus", uri = prometheus },
		{ name = "Kubernetes", uri = kubernetes },
		{ name = "Lefthook", uri = lefthook },
	},
	lspconfig = {
		capabilities = capabilities,
		settings = {
			yaml = {
				schemas = {
					[flux2] = {
						"*.{alert,provider,receiver,helmrelease,helmrepository,gitrepository}.yaml",
						"gotk-*.yaml",
					},
					[gitlab] = {
						"ci/*.{yaml,yml}",
						".gitlab/**/*.{yaml,yml}",
						".gitlab-ci.{yaml,yml}",
					},
					[taskfile] = {
						"**/Taskfile*.{yaml,yml}",
						"taskfiles/**/*.{yaml,yml}",
					},
					[podmonitor] = {
						"*podmonitor*.{yaml,yml}",
					},
					[servicemonitor] = {
						"*servicemonitor*.{yaml,yml}",
					},
					[prometheus] = {
						"*prometheus*.{yaml,yml}",
					},
					[ingress] = {
						"*ingress*.{yaml,yml}",
					},
					[lefthook] = {
						"**/lefthook.*",
					},
					[github] = {
						".github/workflow/**/*.{yaml,yml}",
					},
				},
			},
		},
	},
})

require("lspconfig").helm_ls.setup({
	capabilities = capabilities,
	settings = {
		["helm-ls"] = {
			yamlls = {
				enabled = true,
				enabledForFilesGlob = "*.{yaml,yml}",
				diagnosticsLimit = 50,
				showDiagnosticsDirectly = false,
				path = "yaml-language-server",
				config = {
					schemas = schemas,
					completion = true,
					hover = true,
				},
			},
		},
	},
})

require("lspconfig").yamlls.setup({ cfg })

-- NOTE: restart LSP server avoir problems with Helm-ls
vim.api.nvim_create_autocmd("FileType", {
  pattern = "helm",
  command = "LspRestart",
})
