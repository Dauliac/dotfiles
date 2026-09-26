{
  flake.modules.nixvim.git = {
    plugins = {
      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
          current_line_blame_opts = {
            virt_text = true;
            virt_text_pos = "eol";
            delay = 300;
          };
        };
      };
      neogit = {
        enable = true;
        settings.integrations.diffview = true;
      };
      diffview.enable = true;
      lazygit.enable = true;
      committia.enable = true;
    };
    keymaps = [
      { mode = "n"; key = "]h"; action = "<cmd>Gitsigns next_hunk<CR>"; options.desc = "Next git hunk"; }
      { mode = "n"; key = "[h"; action = "<cmd>Gitsigns prev_hunk<CR>"; options.desc = "Previous git hunk"; }
      { mode = "n"; key = "<leader>hp"; action = "<cmd>Gitsigns preview_hunk<CR>"; options.desc = "Preview git hunk"; }
      { mode = "n"; key = "<leader>hr"; action = "<cmd>Gitsigns reset_hunk<CR>"; options.desc = "Reset git hunk"; }
      { mode = "n"; key = "<leader>hs"; action = "<cmd>Gitsigns stage_hunk<CR>"; options.desc = "Stage git hunk"; }
      { mode = "n"; key = "<leader>hb"; action = "<cmd>Gitsigns blame_line<CR>"; options.desc = "Blame current line"; }
      { mode = "n"; key = "<leader>g"; action = "<Cmd>LazyGit<CR>"; options.desc = "Open lazygit"; }
      { mode = "n"; key = "<leader>D"; action = "<Cmd>DiffviewFileHistory %<CR>"; options.desc = "Current file diff history"; }
    ];
  };
}
