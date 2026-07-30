{
  flake.modules.nixvim.lsp-plugins = {
    plugins = {
      lsp-format.enable = true;
      lsp-lines.enable = true;
      navic.enable = true;
      fidget.enable = true;
      trouble.enable = true;
      todo-comments.enable = true;
      lint.enable = true;
    };
  };
}
