{
  flake.modules.nixvim.lang-rust = { pkgs, ... }: {
    plugins = {
      treesitter.grammarPackages = [
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.rust
      ];
      rustaceanvim.enable = true;
      crates.enable = true;
      neotest.adapters.rust.enable = true;
    };
  };
}
