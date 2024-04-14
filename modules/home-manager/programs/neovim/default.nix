{pkgs, ...}: {
  imports = [
    ./opts.nix
    ./packages.nix
  ];
  programs.nixvim = {
    enable = true;
    colorscheme = "catppuccin-mocha";
    globals.mapleader = ",";
    defaultEditor = true;
    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };
    extraConfigLua = ''
      dofile("${./lua/autopair.lua}")
      dofile("${./lua/catppuccino.lua}")
      dofile("${./lua/chatgpt.lua}")
      dofile("${./lua/cmp.lua}")
      dofile("${./lua/comment.lua}")
      dofile("${./lua/dap.lua}")
      dofile("${./lua/doge.lua}")
      dofile("${./lua/filetree.lua}")
      dofile("${./lua/fzf.lua}")
      dofile("${./lua/gitsigns.lua}")
      dofile("${./lua/glow.lua}")
      dofile("${./lua/indent-blankline-nvim.lua}")
      dofile("${./lua/keymap.lua}")
      dofile("${./lua/lazygit.lua}")
      dofile("${./lua/lsp-colors.lua}")
      dofile("${./lua/lualine.lua}")
      dofile("${./lua/neoclip.lua}")
      dofile("${./lua/neoscroll.lua}")
      dofile("${./lua/noice.lua}")
      dofile("${./lua/notify.lua}")
      dofile("${./lua/null-ls.lua}")
      dofile("${./lua/saga.lua}")
      dofile("${./lua/surround.lua}")
      dofile("${./lua/telescope.lua}")
      dofile("${./lua/todo-comments.lua}")
      dofile("${./lua/treesitter.lua}")
      dofile("${./lua/which-key.lua}")
    '';
    plugins = {
      copilot-lua.enable = true;
      cmp-buffer.enable = true;
      cmp-cmdline.enable = true;
      cmp-emoji.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      cmp.enable = true;
      comment.enable = true;
      copilot-cmp.enable = true;
      flash.enable = true;
      fzf-lua.enable = true;
      goyo.enable = true;
      nvim-autopairs.enable = true;
      undotree.enable = true;
    };
    extraPlugins = with pkgs.vimPlugins; [
      ChatGPT-nvim
      barbar-nvim
      catppuccin-nvim
      diffview-nvim
      firenvim
      gitsigns-nvim
      glow-nvim
      indent-blankline-nvim-lua
      lazygit-nvim
      lsp-colors-nvim
      lsp-format-nvim
      lsp-status-nvim
      lspkind-nvim
      lspsaga-nvim
      lualine-lsp-progress
      lualine-nvim
      neodev-nvim
      neoscroll-nvim
      noice-nvim
      nui-nvim
      null-ls-nvim
      nvim-dap
      nvim-dap-ui
      nvim-dap-virtual-text
      nvim-lspconfig
      nvim-neoclip-lua
      nvim-notify
      nvim-spectre
      nvim-surround
      nvim-tree-lua
      nvim-treesitter-context
      nvim-web-devicons
      plenary-nvim
      registers-nvim
      rust-tools-nvim
      sqlite-lua
      ssr-nvim
      telescope-dap-nvim
      telescope-nvim
      todo-comments-nvim
      trouble-nvim
      vim-gitgutter
      which-key-nvim
      (nvim-treesitter.withPlugins (p: [
        p.javascript
        p.typescript
        p.lua
        p.html
        p.bash
        p.css
        p.jsdoc
        p.nix
        p.scss
        p.tsx
        p.rust
        p.yaml
        p.json
        p.dockerfile
        p.gomod
        p.puppet
        p.scss
        p.sql
        p.terraform
        p.jsonnet
        p.markdown
        p.python
        p.vim
        p.vimdoc
        p.php
        p.vue
      ]))
    ];
  };
}
