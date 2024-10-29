-- Lua
vim.keymap.set("n", "s", require('substitute-nvim').operator, { noremap = true })
vim.keymap.set("n", "ss", require('substitute-nvim').line, { noremap = true })
vim.keymap.set("n", "S", require('substitute-nvim').eol, { noremap = true })
vim.keymap.set("x", "s", require('substitute-nvim').visual, { noremap = true })
