_: {
  flake.modules.nixvim.navigation =
    { pkgs, ... }:
    {
      plugins = {
        fzf-lua = {
          enable = true;
          settings = {
            "1" = "telescope"; # apply telescope-styled fzf-lua profile
          };
        };
        flash.enable = true;
        spider.enable = true;
        spectre.enable = true;
        yazi.enable = true;
      };
      keymaps = [
        # spider word motions
        { mode = [ "n" "o" "x" ]; key = "w"; action.__raw = "function() require('spider').motion('w') end"; options.desc = "Spider-w"; }
        { mode = [ "n" "o" "x" ]; key = "e"; action.__raw = "function() require('spider').motion('e') end"; options.desc = "Spider-e"; }
        { mode = [ "n" "o" "x" ]; key = "b"; action.__raw = "function() require('spider').motion('b') end"; options.desc = "Spider-b"; }
        { mode = [ "n" "o" "x" ]; key = "ge"; action.__raw = "function() require('spider').motion('ge') end"; options.desc = "Spider-ge"; }

        # fzf-lua pickers
        { mode = "n"; key = "<leader>ff"; action.__raw = "function() require('fzf-lua').files() end"; options.desc = "Find files"; }
        { mode = "n"; key = "<leader>fg"; action.__raw = "function() require('fzf-lua').live_grep_glob() end"; options.desc = "Find in files (grep)"; }
        { mode = "n"; key = "<leader>fb"; action.__raw = "function() require('fzf-lua').buffers() end"; options.desc = "Find buffers"; }
        { mode = "n"; key = "<leader>fr"; action.__raw = "function() require('fzf-lua').quickfix() end"; options.desc = "Find quickfix items"; }
        { mode = "n"; key = "<leader>ft"; action.__raw = "function() require('fzf-lua').tabs() end"; options.desc = "Find tabs"; }
        { mode = "n"; key = "<leader>fk"; action.__raw = "function() require('fzf-lua').keymaps() end"; options.desc = "Find keymaps"; }
        { mode = "n"; key = "<leader>fc"; action.__raw = "function() require('fzf-lua').commands() end"; options.desc = "Find commands"; }
        { mode = "n"; key = "<leader>fh"; action.__raw = "function() require('fzf-lua').helptags() end"; options.desc = "Find help tags"; }

        # spectre
        { mode = "n"; key = "<leader>S"; action.__raw = "function() require('spectre').open() end"; options.desc = "Spectre: open"; }
        { mode = "n"; key = "<leader>sw"; action.__raw = "function() require('spectre').open_visual({ select_word = true }) end"; options.desc = "Spectre: search word"; }
        { mode = "v"; key = "<leader>sw"; action.__raw = "function() require('spectre').open_visual() end"; options.desc = "Spectre: search selection"; }
        { mode = "n"; key = "<leader>sp"; action.__raw = "function() require('spectre').open_file_search({ select_word = true }) end"; options.desc = "Spectre: search in current file"; }

        # yazi
        { mode = "n"; key = "<leader>-"; action.__raw = "function() require('yazi').yazi() end"; options.desc = "Open Yazi file manager"; }

        # hlslens (enhanced search)
        { mode = "n"; key = "n"; action = "<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>"; options.desc = "Next search result"; }
        { mode = "n"; key = "N"; action = "<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>"; options.desc = "Prev search result"; }
        { mode = "n"; key = "*"; action = "*<Cmd>lua require('hlslens').start()<CR>"; options.desc = "Search word under cursor"; }
        { mode = "n"; key = "#"; action = "#<Cmd>lua require('hlslens').start()<CR>"; options.desc = "Search word under cursor (back)"; }
        { mode = "n"; key = "g*"; action = "g*<Cmd>lua require('hlslens').start()<CR>"; options.desc = "Partial search word"; }
        { mode = "n"; key = "g#"; action = "g#<Cmd>lua require('hlslens').start()<CR>"; options.desc = "Partial search word (back)"; }
        { mode = "n"; key = "<leader>l"; action = "<Cmd>noh<CR>"; options.desc = "Clear search highlights"; }
      ];
      extraPlugins = with pkgs.vimPlugins; [
        nvim-hlslens
      ];
    };
}
