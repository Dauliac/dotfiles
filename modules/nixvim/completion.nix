{
  flake.modules.nixvim.completion = {
    plugins = {
      cmp-buffer.enable = true;
      cmp-cmdline.enable = true;
      cmp-conventionalcommits.enable = true;
      cmp-dap.enable = true;
      cmp-emoji.enable = true;
      cmp-git.enable = true;
      cmp-look.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-nvim-lua.enable = true;
      cmp-path.enable = true;
      cmp-spell.enable = true;
      cmp-treesitter.enable = true;
      cmp_luasnip.enable = true;
      cmp_yanky.enable = true;
      luasnip.enable = true;
      lspkind.enable = true;
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          snippet.expand = ''
            function(args) require('luasnip').lsp_expand(args.body) end
          '';
          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "path"; }
            { name = "buffer"; }
            { name = "treesitter"; }
            { name = "nvim_lua"; }
            { name = "git"; }
            { name = "dap"; }
            { name = "yanky"; }
            { name = "conventionalcommits"; }
            { name = "spell"; }
            { name = "emoji"; }
            { name = "look"; }
          ];
          mapping = {
            "<Tab>" = ''
              cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                elseif require('luasnip').expand_or_jumpable() then
                  require('luasnip').expand_or_jump()
                else
                  fallback()
                end
              end, { 'i', 's' })
            '';
            "<S-Tab>" = ''
              cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif require('luasnip').jumpable(-1) then
                  require('luasnip').jump(-1)
                else
                  fallback()
                end
              end, { 'i', 's' })
            '';
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.abort()";
            "<CR>" = ''
              cmp.mapping.confirm({
                behavior = cmp.ConfirmBehavior.Replace,
                select = false
              })
            '';
          };
        };
      };
    };
  };
}
