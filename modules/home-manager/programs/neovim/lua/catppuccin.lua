require("catppuccin").setup({
	transparent_background = true,
})

-- if vim.g.started_by_firenvim == false then
vim.cmd.colorscheme("catppuccin-mocha")
-- end

vim.cmd("highlight normal guibg=none ctermbg=none")
vim.cmd("highlight nontext guibg=none ctermbg=none")
vim.cmd("highlight signcolumn guibg=none ctermbg=none")
vim.cmd("highlight vertsplit guibg=none ctermbg=none")
vim.cmd("highlight statusline guibg=none ctermbg=none")
vim.cmd("highlight statuslinenc guibg=none ctermbg=none")
vim.cmd("highlight foldcolumn guibg=none ctermbg=none")
vim.cmd("highlight colorcolumn guibg=none ctermbg=none")
vim.cmd("highlight cursorline guibg=none ctermbg=none")
vim.cmd("highlight cursorcolumn guibg=none ctermbg=none")
