local function set_telescope_keymaps()
	vim.keymap.set("n", "<leader>fp", function()
		require("telescope").extensions.ghq.list()
	end, {
		desc = "Project explorer",
		noremap = true,
		silent = true,
	})
end

local function set_fzf_keymap()
	vim.keymap.set("n", "<leader>f", function() end, { desc = "Fzf prefix" })
	vim.keymap.set("n", "<leader>ff", function()
		require("fzf-lua").files()
	end, { desc = "find files", silent = true, noremap = true })
	vim.keymap.set("n", "<leader>fg", function()
		require("fzf-lua").live_grep_glob()
	end, { desc = "find inside files", noremap = true, silent = true })
	vim.keymap.set("n", "<leader>fb", function()
		require("fzf-lua").buffers()
	end, { desc = "find buffers", noremap = true, silent = true })
	vim.keymap.set("n", "<leader>fr", function()
		require("fzf-lua").quickfix()
	end, { desc = "find qwick fixes", noremap = true, silent = true })
	vim.keymap.set("n", "<leader>ft", function()
		require("fzf-lua").tabs()
	end, { desc = "find tabs", noremap = true, silent = true })
end

local function set_nvim_tree_keymap()
  vim.keymap.set("n", "<leader>-", function()
	  require("yazi").yazi()
  end)
end

local function set_spectre_keymap()
	vim.keymap.set("n", "<leader>s", function() end, { desc = "Spectre prefix" })
	vim.keymap.set("n", "<leader>S", function()
		require("spectre").open()
	end, { desc = "Open Spectre" })
	vim.keymap.set("n", "<leader>sw", function()
		require("spectre").open_visual({ select_word = true })
	end, { desc = "Search current word" })
	vim.keymap.set("v", "<leader>sw", function()
		require("spectre").open_visual()
	end, { desc = "Search current word" })
	vim.keymap.set("n", "<leader>sp", function()
		require("spectre").open_file_search({ select_word = true })
	end, { desc = "Search on current file" })
end

local function set_trouble_keymap()
	vim.keymap.set("n", "<leader>x", function() end, { desc = "Trouble prefix" })
	vim.keymap.set("n", "<leader>xx", function()
		require("trouble").open()
	end, { desc = "Open trouble" })
	vim.keymap.set("n", "<leader>xw", function()
		require("trouble").open("workspace_diagnostics")
	end, { desc = "Open workspace trouble" })

	vim.keymap.set("n", "<leader>xd", function()
		require("trouble").open("document_diagnostics")
	end, { desc = "Open document trouble" })
	vim.keymap.set("n", "<leader>xl", function()
		require("trouble").open("quickfix")
	end, { desc = "Open quickfix trouble" })
	vim.keymap.set("n", "<leader>xq", function()
		require("trouble").open("loclist")
	end, { desc = "Open loclist trouble" })
	vim.keymap.set("n", "gR", function()
		require("trouble").open("lsp_references")
	end, { desc = "Open lsp references trouble" })
end

local function set_dap_keymap()
	vim.keymap.set("n", "<F5>", function()
		require("dap").continue()
	end, { desc = "DAP: Continue execution" })
	vim.keymap.set("n", "<F10>", function()
		require("dap").step_over()
	end, { desc = "DAP: Step over" })
	vim.keymap.set("n", "<F11>", function()
		require("dap").step_into()
	end, { desc = "DAP: Step into" })
	vim.keymap.set("n", "<F12>", function()
		require("dap").step_out()
	end)
	vim.keymap.set("n", "<leader>b", function()
		require("dap").toggle_breakpoint()
	end, { desc = "DAP: Toggle breakpoint" })
end

local function set_todo_comments_keymap()
	vim.keymap.set("n", "]t", function()
		require("todo-comments").jump_next()
	end, { desc = "Next todo comment" })
	vim.keymap.set("n", "[t", function()
		require("todo-comments").jump_prev()
	end, { desc = "Previous todo comment" })
	vim.keymap.set("n", "]t", function()
		require("todo-comments").jump_next({ keywords = { "ERROR", "WARNING" } })
	end, { desc = "Next error/warning todo comment" })
end

local function set_undotree_keymap()
	vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, {
		desc = "Toggle undotree",
	})
end

local function set_goyo_keymap()
	vim.keymap.set("n", "<leader>z", vim.cmd.Goyo, {
		desc = "Toggle goyo zen mode",
	})
end
local function set_diffview_keymap()
	vim.keymap.set("n", "<leader>D", "<Cmd>DiffviewFileHistory %<CR>", {
		desc = "Toggle current file history",
	})
end

local function set_lazygit_keymap()
	vim.keymap.set("n", "<leader>g", vim.cmd.LazyGit, {
		desc = "Open lazygit",
	})
end

local function set_hlslens()
	local kopts = { noremap = true, silent = true }
	vim.keymap.set(
		"n",
		"n",
		[[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
		kopts
	)
	vim.keymap.set(
		"n",
		"N",
		[[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
		kopts
	)
	vim.keymap.set("n", "*", [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
	vim.keymap.set("n", "#", [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
	vim.keymap.set("n", "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
	vim.keymap.set("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)
	vim.keymap.set("n", "<Leader>l", "<Cmd>noh<CR>", kopts)
end

local function set_sops_keymaps()
	vim.keymap.set("n", "<leader>se", function()
		vim.cmd.SopsEncrypt()
	end, { desc = "Sops: [E]ncrypt file" })
	vim.keymap.set("n", "<leader>sd", function()
		vim.cmd.SopsDecrypt()
	end, { desc = "Sops: [D]ecrypt file" })
end

local function claude_code()
  vim.keymap.set('n', '<leader>cc', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude Code' })
end

local function set_keymaps()
	vim.g.mapleader = ","

	vim.keymap.set("n", "<leader>f", function() end, {
		desc = "telescope and fzf prefix",
	})
	set_dap_keymap()
	set_diffview_keymap()
	set_fzf_keymap()
	set_goyo_keymap()
	set_lazygit_keymap()
	set_nvim_tree_keymap()
	set_spectre_keymap()
	set_telescope_keymaps()
	set_todo_comments_keymap()
	set_trouble_keymap()
	set_undotree_keymap()
  claude_code()
	set_hlslens()
	set_sops_keymaps()
end
return {
	set_keymaps(),
}
