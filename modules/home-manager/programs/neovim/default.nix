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
  lsp-lens-nvim =
    pkgs.vimUtils.buildVimPlugin
    {
      name = "lsp-lens-nvim";
      src = "${inputs.lsp-lens-nvim.outPath}";
    };
  yaml-companion-nvim =
    pkgs.vimUtils.buildVimPlugin
      {
        name = "yaml-companion-nvim";
        src = "${inputs.yaml-companion-nvim.outPath}";
      };
in {
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
      # treesitter-context.enable = true;
      ccc.enable = true;
      cmp-buffer.enable = true;
      cmp-cmdline.enable = true;
      cmp-conventionalcommits.enable = true;
      cmp-emoji.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      cmp.enable = true;
      comment.enable = true;
      copilot-cmp.enable = true;
      copilot-lua.enable = true;
      dressing.enable = true;
      flash.enable = true;
      fzf-lua.enable = true;
      goyo.enable = true;
      lsp-format.enable = true;
      lsp-lines.enable = true;
      lsp.enable = true;
      lspkind.enable = true;
      lspsaga.enable = true;
      neo-tree.enable = true;
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
    };
    extraPlugins = with pkgs.vimPlugins; [
      which-key-nvim
      vim-gitgutter
      telescope-nvim
      telescope-dap-nvim
      ssr-nvim
      sqlite-lua
      sonicpi-nvim
      lsp-lens-nvim
      rustaceanvim
      rust-tools-nvim
      registers-nvim
      plenary-nvim
      nvim-spectre
      nvim-neoclip-lua
      nvim-lspconfig
      nvim-dap-virtual-text
      nvim-dap-ui
      nvim-dap
      null-ls-nvim
      nui-nvim
      noice-nvim
      neoscroll-nvim
      nvim-hlslens
      neodev-nvim
      lualine-nvim
      lualine-lsp-progress
      lsp-status-nvim
      lsp-inlayhints-nvim
      lsp-colors-nvim
      lazygit-nvim
      indent-blankline-nvim-lua
      glow-nvim
      gitsigns-nvim
      firenvim
      diffview-nvim
      crates-nvim
      catppuccin-nvim
      vim-helm
      barbar-nvim
      ChatGPT-nvim
      yaml-companion-nvim
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
      dofile("${./lua/chatgpt.lua}")
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
      dofile("${./lua/keymap.lua}")
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
      dofile("${./lua/telescope.lua}")
      dofile("${./lua/todo-comments.lua}")
      dofile("${./lua/treesitter.lua}")
      dofile("${./lua/which-key.lua}")
      require("sonicpi").setup({
        server_dir = "${pkgs.sonic-pi}/app/server",
      })
    '';
  };
}
