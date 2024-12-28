local trouble = require("trouble.sources.telescope")

local telescope = require("telescope")

telescope.setup({
  defaults = {
    mappings = {
      i = { ["<c-t>"] = trouble.open },
      n = { ["<c-t>"] = trouble.open },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",    -- or "ignore_case" or "respect_case"
    },
  },
})

telescope.load_extension("dap")
telescope.load_extension("yaml_schema")
