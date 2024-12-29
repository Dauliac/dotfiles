---
vim.g.firenvim_config = {
	globalSettings = { alt = "all" },
	localSettings = {
		[".*"] = {
			cmdline = "neovim",
			content = "text",
			priority = 0,
			selector = "textarea",
			takeover = "always",
		},
	},
}

if vim.g.started_by_firenvim == true then
	vim.fn["firenvim#install"](0)
	vim.o.laststatus = 0
	require("catppuccin").setup({
		flavour = "latte",
		transparent_background = true,
	})
	vim.cmd.colorscheme("catppuccin-latte")
	vim.api.nvim_set_keymap("n", "<Esc><Esc>", "<Cmd>call firenvim#focus_page()<CR>", {})
	-- vim.api.nvim_create_autocmd({ "BufEnter" }, {
	--   pattern = "github.com_*.txt",
	--   command = "set filetype=markdown",
	-- })
	-- vim.api.nvim_create_autocmd({ "BufEnter" }, {
	--   pattern = "gitlab*.txt",
	--   command = "set filetype=markdown",
	-- })
end
