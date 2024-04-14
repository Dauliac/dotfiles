local trouble = require("trouble.providers.telescope")

local telescope = require("telescope")

telescope.setup({
  defaults = {
    mappings = {
      i = { ["<c-t>"] = trouble.open_with_trouble },
      n = { ["<c-t>"] = trouble.open_with_trouble },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,                -- false will only do exact matching
      override_generic_sorter = true, -- override the generic sorter
      override_file_sorter = true, -- override the file sorter
      case_mode = "smart_case",    -- or "ignore_case" or "respect_case"
    },
  },
})

telescope.load_extension("dap")
