local function set_telescope_keymaps()
	vim.api.nvim_set_keymap("n", "<leader>fp", "<Cmd>lua require('telescope').extensions.ghq.list()<CR>", {
		desc = "Project explorer",
		noremap = true,
		silent = true,
	})
end

local function set_fzf_keymap()
	vim.keymap.set("n", "<leader>ff", "<Cmd>lua require('fzf-lua').files()<CR>", {
		desc = "find files",
		silent = true,
		noremap = true,
	})
	vim.api.nvim_set_keymap("n", "<leader>fg", "<Cmd>lua require('fzf-lua').live_grep_glob()<CR>", {
		desc = "find inside files",
		noremap = true,
		silent = true,
	})
	vim.api.nvim_set_keymap("n", "<leader>fb", "<Cmd>lua require('fzf-lua').buffers()<CR>", {
		desc = "find buffers",
		noremap = true,
		silent = true,
	})
	vim.api.nvim_set_keymap("n", "<leader>fr", "<Cmd>lua require('fzf-lua').quickfix()<CR>", {
		desc = "find qwick fixes",
		noremap = true,
		silent = true,
	})
	vim.api.nvim_set_keymap("n", "<leader>ft", "<Cmd>lua require('fzf-lua').tabs()<CR>", {
		desc = "find tabs",
		noremap = true,
		silent = true,
	})
end

local function set_nvim_tree_keymap()
	vim.api.nvim_set_keymap(
		"n",
		"<leader>e",
		":Neotree<CR>",
		{ desc = "Toggle Nvim tree", noremap = true, silent = true }
	)
end

local function set_spectre_keymap()
	vim.keymap.set("n", "<leader>s", function() end, {
		desc = "Spectre prefix",
	})
	vim.keymap.set("n", "<leader>S", '<cmd>lua require("spectre").open()<CR>', {
		desc = "Open Spectre",
	})
	vim.keymap.set("n", "<leader>sw", '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
		desc = "Search current word",
	})
	vim.keymap.set("v", "<leader>sw", '<esc><cmd>lua require("spectre").open_visual()<CR>', {
		desc = "Search current word",
	})
	vim.keymap.set("n", "<leader>sp", '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
		desc = "Search on current file",
	})
end

local function set_trouble_keymap()
	vim.keymap.set("n", "<leader>x", function() end, {
		desc = "Trouble prefix",
	})
	vim.keymap.set("n", "<leader>xx", function()
		require("trouble").open()
	end, {
		desc = "Open trouble",
	})
	vim.keymap.set("n", "<leader>xw", function()
		require("trouble").open("workspace_diagnostics")
	end, {
		desc = "Open workspace trouble",
	})

	vim.keymap.set("n", "<leader>xd", function()
		require("trouble").open("document_diagnostics")
	end, {
		desc = "Open document trouble",
	})
	vim.keymap.set("n", "<leader>xl", function()
		require("trouble").open("quickfix")
	end, {
		desc = "Open quickfix trouble",
	})
	vim.keymap.set("n", "<leader>xq", function()
		require("trouble").open("loclist")
	end, {
		desc = "Open loclist trouble",
	})
	vim.keymap.set("n", "gR", function()
		require("trouble").open("lsp_references")
	end, {
		desc = "Open lsp references trouble",
	})
end

local function set_dap_keymap()
	vim.keymap.set("n", "<F5>", require("dap").continue, { desc = "DAP: Continue execution" })
	vim.keymap.set("n", "<F10>", require("dap").step_over, { desc = "DAP: Step over" })
	vim.keymap.set("n", "<F11>", require("dap").step_into, { desc = "DAP: Step into" })
	vim.keymap.set("n", "<F12>", require("dap").step_out)
	vim.keymap.set("n", "<leader>b", require("dap").toggle_breakpoint, { desc = "DAP: Toggle breakpoint" })
end

local function set_todo_comments_keymap()
	vim.keymap.set("n", "]t", function()
		require("todo-comments").jump_next()
	end, { desc = "Next todo comment" })

	vim.keymap.set("n", "[t", function()
		require("todo-comments").jump_prev()
	end, { desc = "Previous todo comment" })

	-- You can also specify a list of valid jump keywords

	vim.keymap.set("n", "]t", function()
		require("todo-comments").jump_next({ keywords = { "ERROR", "WARNING" } })
	end, { desc = "Next error/warning todo comment" })
end

local function set_barbar_keymap()
	local map = vim.api.nvim_set_keymap
	local opts = { noremap = true, silent = true }

	-- Move to previous/next
	map("n", "<A-,>", "<Cmd>BufferPrevious<CR>", opts)
	map("n", "<A-.>", "<Cmd>BufferNext<CR>", opts)
	-- Re-order to previous/next
	map("n", "<A-<>", "<Cmd>BufferMovePrevious<CR>", opts)
	map("n", "<A->>", "<Cmd>BufferMoveNext<CR>", opts)
	-- Goto buffer in position...
	map("n", "<A-1>", "<Cmd>BufferGoto 1<CR>", opts)
	map("n", "<A-2>", "<Cmd>BufferGoto 2<CR>", opts)
	map("n", "<A-3>", "<Cmd>BufferGoto 3<CR>", opts)
	map("n", "<A-4>", "<Cmd>BufferGoto 4<CR>", opts)
	map("n", "<A-5>", "<Cmd>BufferGoto 5<CR>", opts)
	map("n", "<A-6>", "<Cmd>BufferGoto 6<CR>", opts)
	map("n", "<A-7>", "<Cmd>BufferGoto 7<CR>", opts)
	map("n", "<A-8>", "<Cmd>BufferGoto 8<CR>", opts)
	map("n", "<A-9>", "<Cmd>BufferGoto 9<CR>", opts)
	map("n", "<A-0>", "<Cmd>BufferLast<CR>", opts)
	-- Pin/unpin buffer
	map("n", "<A-p>", "<Cmd>BufferPin<CR>", opts)
	-- Close buffer
	map("n", "<A-c>", "<Cmd>BufferClose<CR>", opts)
	-- Wipeout buffer
	--                 :BufferWipeout
	-- Close commands
	--                 :BufferCloseAllButCurrent
	--                 :BufferCloseAllButPinned
	--                 :BufferCloseAllButCurrentOrPinned
	--                 :BufferCloseBuffersLeft
	--                 :BufferCloseBuffersRight
	-- Magic buffer-picking mode
	map("n", "<C-p>", "<Cmd>BufferPick<CR>", opts)
	-- Sort automatically by...
	map("n", "<Space>bb", "<Cmd>BufferOrderByBufferNumber<CR>", opts)
	map("n", "<Space>bd", "<Cmd>BufferOrderByDirectory<CR>", opts)
	map("n", "<Space>bl", "<Cmd>BufferOrderByLanguage<CR>", opts)
	map("n", "<Space>bw", "<Cmd>BufferOrderByWindowNumber<CR>", opts)

	-- Other:
	-- :BarbarEnable - enables barbar (enabled by default)
	-- :BarbarDisable - very bad command, should never be used
end

local function set_undotree_keymap()
	vim.keymap.set("n", "<leader>u", "<Cmd>UndotreeToggle<CR>", {
		desc = "Toggle undotree",
	})
end

local function set_goyo_keymap()
	vim.keymap.set("n", "<leader>z", "<Cmd>Goyo<CR>", {
		desc = "Toggle goyo",
	})
end
local function set_diffview_keymap()
	vim.keymap.set("n", "<leader>D", "<Cmd>DiffviewFileHistory %<CR>", {
		desc = "Toggle current file history",
	})
end

local function set_lazygit_keymap()
	vim.keymap.set("n", "<leader>g", "<Cmd>LazyGit<CR>", {
		desc = "Open lazygit",
	})
end

local function set_chatgpt_keymap()
	vim.keymap.set("n", "<leader>U", "<Cmd>ChatGPT<CR>", {
		desc = "Open ChatGPT prompt",
	})
	vim.keymap.set("n", "<leader>I", "<Cmd>ChatGPTEditWithInstruction<CR>", {
		desc = "Edit current selection with ChatGPT",
	})
	vim.keymap.set("n", "<leader>O", "<Cmd>ChatGPTRun docstring<CR>", {
		desc = "Generate docstring",
	})
	vim.keymap.set("n", "<leader>P", "<Cmd>ChatGPTRun add_tests<CR>", {
		desc = "Generate tests",
	})
end

local function set_code_action()
	vim.keymap.set("n", "<leader>a", function()
		vim.cmd.RustLsp("codeAction") -- supports rust-analyzer's grouping
		-- or vim.lsp.buf.codeAction() if you don't want grouping.
	end, { silent = true, buffer = bufnr })
end

local function set_hlslens()
	local kopts = { noremap = true, silent = true }
	vim.api.nvim_set_keymap(
		"n",
		"n",
		[[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
		kopts
	)
	vim.api.nvim_set_keymap(
		"n",
		"N",
		[[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
		kopts
	)
	vim.api.nvim_set_keymap("n", "*", [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
	vim.api.nvim_set_keymap("n", "#", [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
	vim.api.nvim_set_keymap("n", "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
	vim.api.nvim_set_keymap("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)

	vim.api.nvim_set_keymap("n", "<Leader>l", "<Cmd>noh<CR>", kopts)
end

local function set_sops_keymaps()
	vim.keymap.set("n", "<leader>se", vim.cmd.SopsEncrypt, { desc = "Sops: [E]ncrypt file" })
	vim.keymap.set("n", "<leader>sd", vim.cmd.SopsDecrypt, { desc = "Sops: [D]ecrypt file" })
end

local function set_neoclip_keymaps()
	vim.keymap.set("n", "<leader>c", vim.cmd.Telescope("neoclip"), { desc = "Neoclip: [c]lipboard manager" })
end

local function set_keymaps()
	vim.g.mapleader = ","

	vim.keymap.set("n", "<leader>f", function() end, {
		desc = "telescope and fzf prefix",
	})
	set_barbar_keymap()
	set_chatgpt_keymap()
	set_code_action()
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
	set_hlslens()
	set_sops_keymaps()
  set_neoclip_keymaps()
end
return {
	set_keymaps(),
}
