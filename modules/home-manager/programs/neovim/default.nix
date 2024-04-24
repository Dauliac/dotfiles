{
  inputs,
  pkgs,
  ...
}: let
  sonicpi-nvim =
    pkgs.vimUtils.buildVimPlugin
    {
      name = "sonicpi";
      src = "${inputs.sonicpi-nvim.outPath}";
    };
in {
  imports = [
    ./opts.nix
    ./packages.nix
  ];
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    colorscheme = "catppuccin-mocha";
    globals.mapleader = ",";
    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };
    extraConfigLua = ''
      dofile("${./lua/autopair.lua}")
      dofile("${./lua/catppuccin.lua}")
      dofile("${./lua/chatgpt.lua}")
      dofile("${./lua/cmp.lua}")
      dofile("${./lua/comment.lua}")
      dofile("${./lua/dap.lua}")
      dofile("${./lua/doge.lua}")
      dofile("${./lua/filetree.lua}")
      dofile("${./lua/fzf.lua}")
      dofile("${./lua/lsp.lua}")
      dofile("${./lua/gitsigns.lua}")
      dofile("${./lua/glow.lua}")
      dofile("${./lua/indent-blankline-nvim.lua}")
      dofile("${./lua/init.lua}")
      dofile("${./lua/keymap.lua}")
      dofile("${./lua/lazygit.lua}")
      dofile("${./lua/lsp-colors.lua}")
      dofile("${./lua/lspkind.lua}")
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
      require("sonicpi").setup({
        server_dir = "${pkgs.sonic-pi}/app/server",
      })
    '';
    plugins = {
      cmp-buffer.enable = true;
      cmp-cmdline.enable = true;
      cmp-emoji.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      cmp.enable = true;
      cmp-conventionalcommits.enable = true;
      comment.enable = true;
      copilot-cmp.enable = true;
      copilot-lua.enable = true;
      flash.enable = true;
      fzf-lua.enable = true;
      goyo.enable = true;
      lsp-format.enable = true;
      lsp-lines.enable = true;
      lsp.enable = true;
      lspkind.enable = true;
      lspsaga.enable = true;
      neogit.enable = true;
      nvim-autopairs.enable = true;
      todo-comments.enable = true;
      treesitter-context.enable = true;
      trouble.enable = true;
      undotree.enable = true;
    };
    extraPlugins = with pkgs.vimPlugins; [
      ChatGPT-nvim
      barbar-nvim
      catppuccin-nvim
      crates-nvim
      rustaceanvim
      diffview-nvim
      firenvim
      gitsigns-nvim
      glow-nvim
      indent-blankline-nvim-lua
      lazygit-nvim
      lsp-colors-nvim
      lsp-status-nvim
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
      nvim-web-devicons
      plenary-nvim
      registers-nvim
      rust-tools-nvim
      sonicpi-nvim
      sqlite-lua
      ssr-nvim
      telescope-dap-nvim
      telescope-nvim
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
