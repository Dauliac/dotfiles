-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("neo-tree").setup({
  window = {
    position = "right",
    width = 50,
  },
  source_selector = {
    winbar = false,
    statusline = false,
  },
})
