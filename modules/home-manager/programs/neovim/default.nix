{
  inputs,
  pkgs,
  ...
}:
let
  lsp-lens-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "lsp-lens-nvim";
    src = "${inputs.lsp-lens-nvim.outPath}";
    doCheck = false;
  };
  yaml-companion-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "yaml-companion-nvim";
    src = "${inputs.yaml-companion-nvim.outPath}";
    doCheck = false;
  };
in
{
  imports = [
    ./opts.nix
    ./packages.nix
  ];
  home.sessionVariables = {
    VISUAL = "nvim";
  };
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
    plugins = {
      ccc.enable = true;
      cmp-buffer.enable = true;
      cmp-cmdline.enable = true;
      cmp-conventionalcommits.enable = true;
      cmp-emoji.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      cmp.enable = true;
      cmp-dap.enable = true;
      comment.enable = true;
      copilot-cmp.enable = false;
      copilot-lua.enable = false;
      dressing.enable = true;
      flash.enable = true;
      fzf-lua.enable = true;
      goyo.enable = true;
      lsp-format.enable = true;
      lsp-lines.enable = true;
      lsp.enable = true;
      lspkind.enable = true;
      lspsaga.enable = true;
      # neo-tree.enable = true;
      neogit.enable = true;
      noice.enable = true;
      nvim-autopairs.enable = true;
      spider.enable = true;
      todo-comments.enable = true;
      treesitter.enable = true;
      trim.enable = true;
      trouble.enable = true;
      undotree.enable = true;
      vim-surround.enable = true;
      web-devicons.enable = true;
      dap.enable = true;
      # dap-rr.enable = true;
      # dap-go.enable = true;
      # dap-python.enable = true;
      # dap-ui.enable = true;
      # dap-virtual-text.enable = true;
      neotest.enable = true;
    };
    extraPlugins = with pkgs.vimPlugins; [
      barbar-nvim
      catppuccin-nvim
      crates-nvim
      diffview-nvim
      firenvim
      gitsigns-nvim
      glow-nvim
      indent-blankline-nvim-lua
      lazygit-nvim
      lsp-colors-nvim
      lsp-inlayhints-nvim
      lsp-lens-nvim
      lsp-status-nvim
      lualine-lsp-progress
      lualine-nvim
      neodev-nvim
      neoscroll-nvim
      noice-nvim
      nui-nvim
      null-ls-nvim
      nvim-hlslens
      nvim-lspconfig
      nvim-neoclip-lua
      nvim-sops
      nvim-spectre
      plenary-nvim
      registers-nvim
      rust-tools-nvim
      rustaceanvim
      sqlite-lua
      ssr-nvim
      substitute-nvim
      tailwind-tools-nvim
      tailwindcss-colors-nvim
      telescope-dap-nvim
      nvim-dap-virtual-text
      nvim-dap-go
      nvim-dap-ui
      nvim-dap-rr
      telescope-nvim
      vim-gitgutter
      vim-helm
      which-key-nvim
      yaml-companion-nvim
      yazi-nvim
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
        p.helm
        p.vim
        p.vimdoc
        p.php
        p.vue
      ]))
    ];
    extraConfigLua = ''
      dofile("${./lua/autopair.lua}")
      dofile("${./lua/catppuccin.lua}")
      dofile("${./lua/cmp.lua}")
      dofile("${./lua/comment.lua}")
      dofile("${./lua/dap.lua}")
      dofile("${./lua/dressing.lua}")
      dofile("${./lua/doge.lua}")
      dofile("${./lua/filetree.lua}")
      dofile("${./lua/fzf.lua}")
      dofile("${./lua/gitsigns.lua}")
      dofile("${./lua/glow.lua}")
      dofile("${./lua/hlslens.lua}")
      dofile("${./lua/indent-blankline-nvim.lua}")
      dofile("${./lua/init.lua}")
      -- dofile("${./lua/keymap.lua}")
      dofile("${./lua/lazygit.lua}")
      dofile("${./lua/lsp-colors.lua}")
      dofile("${./lua/lsp-lens.lua}")
      dofile("${./lua/lsp.lua}")
      dofile("${./lua/lspkind.lua}")
      dofile("${./lua/lualine.lua}")
      dofile("${./lua/neoclip.lua}")
      dofile("${./lua/neoscroll.lua}")
      dofile("${./lua/noice.lua}")
      dofile("${./lua/notify.lua}")
      dofile("${./lua/null-ls.lua}")
      dofile("${./lua/saga.lua}")
      dofile("${./lua/sops.lua}")
      dofile("${./lua/telescope.lua}")
      dofile("${./lua/todo-comments.lua}")
      dofile("${./lua/treesitter.lua}")
      dofile("${./lua/which-key.lua}")
      dofile("${./lua/tailwind.lua}")
    '';
  };
}
