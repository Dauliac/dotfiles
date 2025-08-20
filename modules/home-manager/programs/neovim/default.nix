{
  inputs,
  pkgs,
  ...
}:
let
  yaml-companion-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "yaml-companion-nvim";
    src = "${inputs.yaml-companion-nvim.outPath}";
    doCheck = false;
  };
  commander-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "commander";
    src = "${inputs.commander-nvim.outPath}";
    doCheck = false;
  };
in
{
  imports = [
    ./opts.nix
    ./packages.nix
    ./lsp.nix
  ];
  home.sessionVariables = {
    VISUAL = "nvim";
  };
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    globals.mapleader = ",";
    colorschemes.catppuccin.enable = true;
    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };
    plugins = {
      ccc.enable = true;
      # claude-code.enable = true;
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
      yanky.enable = true;
      lazygit.enable = true;
      committia.enable = true;
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings.sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
          { name = "treesitter"; }
          { name = "spell"; }
          { name = "git"; }
          { name = "emoji"; }
          { name = "dap"; }
          { name = "look"; }
          { name = "luasnip"; }
          { name = "yanky"; }
          { name = "nvim_lua"; }
          { name = "conventionalcommits"; }
          { name = "copilot"; }
        ];
      };
      comment.enable = true;
      copilot-cmp.enable = true;
      copilot-lua.enable = true;
      distant.enable = true;
      dressing.enable = true;
      diagram.enable = true;
      flash.enable = true;
      lint.enable = true;
      fzf-lua.enable = true;
      goyo.enable = true;
      lsp-format.enable = true;
      lsp-lines.enable = true;
      lsp.enable = true;
      lspkind.enable = true;
      modicator.enable = true;
      navic.enable = true;
      neogit.enable = true;
      noice.enable = true;
      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
        };
      };
      nvim-autopairs.enable = true;
      neotest = {
        enable = true;
        adapters = {
          go.enable = true;
          rust.enable = true;
          jest.enable = true;
          bash.enable = true;
        };
      };
      spider.enable = true;
      todo-comments.enable = true;
      treesitter = {
        enable = true;
        settings.highlight.enable = true;
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
          json
          rust
          go
          typescript
          lua
          make
          python
          cue
          markdown
          nix
          regex
          toml
          vim
          vimdoc
          xml
          yaml
          vrl
        ];
      };
      trim.enable = true;
      trouble.enable = true;
      undotree.enable = true;
      vim-surround.enable = true;
      web-devicons.enable = true;
      dap.enable = true;
      neoscroll.enable = true;
      dap-rr.enable = true;
      dap-go.enable = true;
      dap-python.enable = true;
      dap-ui.enable = true;
      dap-virtual-text.enable = true;
      diffview.enable = true;
      spectre.enable = true;
      yazi.enable = true;
      barbar.enable = true;
      glow.enable = true;
      gitmessenger.enable = true;
      lualine.enable = true;
      indent-blankline.enable = true;
      rustaceanvim = {
        enable = true;
      };
      crates.enable = true;
      nui.enable = true;
      which-key.enable = true;
      gitgutter.enable = true;
      gitsigns.enable = true;
    };
    extraPlugins = with pkgs.vimPlugins; [
      commander-nvim
      neodev-nvim
      nvim-hlslens
      nvim-sops
      plenary-nvim
      ssr-nvim
      substitute-nvim
      vim-helm
      yaml-companion-nvim
    ];
    extraConfigLua = ''
      dofile("${./lua/catppuccin.lua}")
      dofile("${./lua/commander.lua}")
      dofile("${./lua/dressing.lua}")
      dofile("${./lua/fzf.lua}")
      dofile("${./lua/init.lua}")
      dofile("${./lua/keymap.lua}")
      dofile("${./lua/sops.lua}")
    '';
  };
}
