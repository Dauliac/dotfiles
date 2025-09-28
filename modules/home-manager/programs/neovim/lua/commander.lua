local commander = require("commander")

commander.setup({
	components = {
		"DESC",
		"KEYS",
		"CAT",
	},
	sort_by = {
		"DESC",
		"KEYS",
		"CAT",
		"CMD",
	},
	integration = {
		telescope = {
			enable = true,
			theme = require("telescope.themes").commander,
		},
	},
})

local function telescope_keymaps()
	local cat = "Telescope"
	return {
		{
			desc = "Project explorer",
			cmd = function()
				require("telescope").extensions.ghq.list()
			end,
			keys = { "n", "<leader>fp" },
			cat = cat,
		},
		{
			desc = "Open commander",
			cmd = require("commander").show,
			keys = { "n", "<Leader>fc" },
			cat = cat,
		},
	}
end

local function fzf_keymaps()
	local cat = "Fzf"
	return {
		-- {
		--   desc = "Fzf prefix",
		--   cmd = function() end,
		--   keys = { "n", "<leader>f" },
		--   cat = cat,
		-- },
		{
			desc = "Find files",
			cmd = function()
				require("fzf-lua").files()
			end,
			keys = { "n", "<leader>ff" },
			cat = cat,
		},
		{
			desc = "Find inside files",
			cmd = function()
				require("fzf-lua").live_grep_glob()
			end,
			keys = { "n", "<leader>fg" },
			cat = cat,
		},
		{
			desc = "Find buffers",
			cmd = function()
				require("fzf-lua").buffers()
			end,
			keys = { "n", "<leader>fb" },
			cat = cat,
		},
		{
			desc = "Find quick fixes",
			cmd = function()
				require("fzf-lua").quickfix()
			end,
			keys = { "n", "<leader>fr" },
			cat = cat,
		},
		{
			desc = "Find tabs",
			cmd = function()
				require("fzf-lua").tabs()
			end,
			keys = { "n", "<leader>ft" },
			cat = cat,
		},
	}
end

local function nvim_tree_keymaps()
	return {
		{
			desc = "Toggle Nvim tree",
			cmd = "<CMD>Neotree<CR>",
			keys = { "n", "<leader>e" },
		},
	}
end

local function spectre_keymaps()
	local cat = "Spectre"
	return {
		{
			desc = "Spectre prefix",
			cmd = function() end,
			keys = { "n", "<leader>s" },
			cat = cat,
		},
		{
			desc = "Open Spectre",
			cmd = function()
				require("spectre").open()
			end,
			keys = { "n", "<leader>S" },
			cat = cat,
		},
		{
			desc = "Search current word",
			cmd = function()
				require("spectre").open_visual({ select_word = true })
			end,
			keys = { "n", "<leader>sw" },
			cat = cat,
		},
		{
			desc = "Search current word (visual)",
			cmd = function()
				require("spectre").open_visual()
			end,
			keys = { "v", "<leader>sw" },
			cat = cat,
		},
		{
			desc = "Search on current file",
			cmd = function()
				require("spectre").open_file_search({ select_word = true })
			end,
			keys = { "n", "<leader>sp" },
			cat = cat,
		},
	}
end

local function trouble_keymaps()
	local cat = "Trouble"
	return {
		{
			desc = "Trouble prefix",
			cmd = function() end,
			keys = { "n", "<leader>x" },
			cat = cat,
		},
		{
			desc = "Open trouble",
			cmd = function()
				require("trouble").open()
			end,
			keys = { "n", "<leader>xx" },
			cat = cat,
		},
		{
			desc = "Open workspace trouble",
			cmd = function()
				require("trouble").open("workspace_diagnostics")
			end,
			keys = { "n", "<leader>xw" },
			cat = cat,
		},
		{
			desc = "Open document trouble",
			cmd = function()
				require("trouble").open("document_diagnostics")
			end,
			keys = { "n", "<leader>xd" },
			cat = cat,
		},
		{
			desc = "Open quickfix trouble",
			cmd = function()
				require("trouble").open("quickfix")
			end,
			keys = { "n", "<leader>xl" },
			cat = cat,
		},
		{
			desc = "Open loclist trouble",
			cmd = function()
				require("trouble").open("loclist")
			end,
			keys = { "n", "<leader>xq" },
			cat = cat,
		},
		{
			desc = "Open LSP references trouble",
			cmd = function()
				require("trouble").open("lsp_references")
			end,
			keys = { "n", "gR" },
			cat = cat,
		},
	}
end

local function dap_keymaps()
	local cat = "DAP"
	return {
		{
			desc = "DAP: Continue execution",
			cmd = function()
				require("dap").continue()
			end,
			keys = { "n", "<F5>" },
			cat = cat,
		},
		{
			desc = "DAP: Step over",
			cmd = function()
				require("dap").step_over()
			end,
			keys = { "n", "<F10>" },
			cat = cat,
		},
		{
			desc = "DAP: Step into",
			cmd = function()
				require("dap").step_into()
			end,
			keys = { "n", "<F11>" },
			cat = cat,
		},
		{
			desc = "DAP: Step out",
			cmd = function()
				require("dap").step_out()
			end,
			keys = { "n", "<F12>" },
			cat = cat,
		},
		{
			desc = "DAP: Toggle breakpoint",
			cmd = function()
				require("dap").toggle_breakpoint()
			end,
			keys = { "n", "<leader>b" },
			cat = cat,
		},
	}
end

local function todo_keymaps()
	local cat = "todo"
	return {
		{
			desc = "Next todo comment",
			cmd = function()
				require("todo-comments").jump_next()
			end,
			keys = { "n", "]t" },
			cat = cat,
		},
		{
			desc = "Previous todo comment",
			cmd = function()
				require("todo-comments").jump_prev()
			end,
			keys = { "n", "[t" },
			cat = cat,
		},
		{
			desc = "Next error/warning todo comment",
			cmd = function()
				require("todo-comments").jump_next({ keywords = { "ERROR", "WARNING" } })
			end,
			keys = { "n", "]t" },
			cat = cat,
		},
	}
end

-- CMP keymaps removed - now handled by nixvim configuration in default.nix
-- This avoids fallback function conflicts with commander plugin

local function misc_keymaps()
	return {
		{
			desc = "Toggle Undotree",
			cmd = vim.cmd.UndotreeToggle,
			keys = { "n", "<leader>u" },
			cat = "git",
		},
		{
			desc = "Toggle Goyo zen mode",
			cmd = vim.cmd.Goyo,
			keys = { "n", "<leader>z" },
		},
		{
			desc = "Toggle current file history",
			cmd = "<Cmd>DiffviewFileHistory %<CR>",
			keys = { "n", "<leader>D" },
			cat = "git",
		},
		{
			desc = "Open lazygit",
			cmd = vim.cmd.LazyGit,
			keys = { "n", "<leader>g" },
			cat = "git",
		},
		{
			desc = "Open file manager (Yazi)",
			cmd = function()
				require("yazi").yazi()
			end,
			keys = { "n", "<leader>-" },
			cat = "file",
		},
		{
			desc = "Toggle Claude Code",
			cmd = "<cmd>ClaudeCode<CR>",
			keys = { "n", "<leader>cc" },
			cat = "ai",
		},
	}
end

local function sops_keymaps()
	local cat = "sops"
	return {
		{
			desc = "Sops: Encrypt file",
			cmd = vim.cmd.SopsEncrypt,
			keys = { "n", "<leader>se" },
			cat = cat,
		},
		{
			desc = "Sops: Decrypt file",
			cmd = vim.cmd.SopsDecrypt,
			keys = { "n", "<leader>sd" },
			cat = cat,
		},
	}
end

local function hlslens_keymaps()
	local cat = "search"
	return {
		{
			desc = "Next search result (enhanced)",
			cmd = [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
			keys = { "n", "n" },
			cat = cat,
		},
		{
			desc = "Previous search result (enhanced)",
			cmd = [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
			keys = { "n", "N" },
			cat = cat,
		},
		{
			desc = "Search word under cursor (enhanced)",
			cmd = [[*<Cmd>lua require('hlslens').start()<CR>]],
			keys = { "n", "*" },
			cat = cat,
		},
		{
			desc = "Search word under cursor backward (enhanced)",
			cmd = [[#<Cmd>lua require('hlslens').start()<CR>]],
			keys = { "n", "#" },
			cat = cat,
		},
		{
			desc = "Search word under cursor partial (enhanced)",
			cmd = [[g*<Cmd>lua require('hlslens').start()<CR>]],
			keys = { "n", "g*" },
			cat = cat,
		},
		{
			desc = "Search word under cursor partial backward (enhanced)",
			cmd = [[g#<Cmd>lua require('hlslens').start()<CR>]],
			keys = { "n", "g#" },
			cat = cat,
		},
		{
			desc = "Clear search highlights",
			cmd = "<Cmd>noh<CR>",
			keys = { "n", "<Leader>l" },
			cat = cat,
		},
	}
end

local function merge_keymaps(functions)
	local result = {}
	for _, func in ipairs(functions) do
		vim.list_extend(result, func())
	end
	return result
end

vim.g.mapleader = ","
commander.add(merge_keymaps({
	fzf_keymaps,
	nvim_tree_keymaps,
	spectre_keymaps,
	trouble_keymaps,
	dap_keymaps,
	todo_keymaps,
	misc_keymaps,
	telescope_keymaps,
	sops_keymaps,
	hlslens_keymaps,
}))
