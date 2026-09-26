{
  flake.modules.nixvim.lsp-plugins = {
    plugins = {
      lsp-format.enable = true;
      lsp-lines.enable = true;
      navic.enable = true;
      fidget.enable = true;
      trouble.enable = true;
      todo-comments.enable = true;
      # lint (nvim-lint) is a no-op without settings.lintersByFt = { ... };
      # re-enable and populate per-language linters when needed.
    };
    keymaps = [
      # trouble
      { mode = "n"; key = "<leader>xx"; action.__raw = "function() require('trouble').toggle('diagnostics') end"; options.desc = "Trouble: workspace diagnostics"; }
      { mode = "n"; key = "<leader>xd"; action.__raw = "function() require('trouble').toggle({ mode = 'diagnostics', filter = { buf = 0 } }) end"; options.desc = "Trouble: buffer diagnostics"; }
      { mode = "n"; key = "<leader>xl"; action.__raw = "function() require('trouble').toggle('qflist') end"; options.desc = "Trouble: quickfix"; }
      { mode = "n"; key = "<leader>xq"; action.__raw = "function() require('trouble').toggle('loclist') end"; options.desc = "Trouble: loclist"; }
      { mode = "n"; key = "gR"; action.__raw = "function() require('trouble').toggle('lsp_references') end"; options.desc = "Trouble: LSP references"; }
      { mode = "n"; key = "<leader>xs"; action.__raw = "function() require('trouble').toggle('symbols') end"; options.desc = "Trouble: symbols"; }

      # todo-comments
      { mode = "n"; key = "]t"; action.__raw = "function() require('todo-comments').jump_next() end"; options.desc = "Next todo comment"; }
      { mode = "n"; key = "[t"; action.__raw = "function() require('todo-comments').jump_prev() end"; options.desc = "Prev todo comment"; }
      { mode = "n"; key = "]T"; action.__raw = "function() require('todo-comments').jump_next({ keywords = { 'ERROR', 'WARNING' } }) end"; options.desc = "Next error/warning todo"; }
    ];
    # lsp-lines renders diagnostics as full virtual lines; disable default
    # virtual_text so diagnostics don't render twice.
    extraConfigLua = ''
      vim.diagnostic.config({ virtual_text = false })
    '';
  };
}
