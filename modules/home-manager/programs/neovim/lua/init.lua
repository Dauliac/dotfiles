vim.cmd.syntax("on")

-- Options
vim.opt.clipboard:append({ "unnamedplus" })
vim.opt.cc = "120"
vim.opt.listchars = {
  tab = "▸ ",
  trail = "·",
  extends = "»",
  precedes = "«",
  nbsp = "␣",
  eol = "↲",
}

vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")

vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.smartindent = true
vim.wo.number = true
vim.o.exrc = true
vim.o.secure = true
vim.o.termguicolors = true
vim.o.hlsearch = false
vim.o.hidden = true
vim.o.guicursor = ""
vim.o.scrolloff = 0
vim.wo.signcolumn = "yes"
vim.o.undofile = true
vim.o.incsearch = true
vim.o.updatetime = 50
vim.o.splitbelow = true
vim.o.splitright = true
vim.wo.relativenumber = true
vim.o.sessionoptions = "tabpages,globals"
vim.o.ignorecase = true
vim.o.swapfile = false
vim.o.laststatus = 3
vim.o.re = 0
vim.o.eol = true
