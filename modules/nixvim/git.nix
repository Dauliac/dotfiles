{
  flake.modules.nixvim.git = {
    plugins = {
      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
          current_line_blame_opts = {
            virt_text = true;
            virt_text_pos = "eol";
            delay = 300;
          };
        };
      };
      neogit.enable = true;
      diffview.enable = true;
      gitmessenger.enable = true;
      lazygit.enable = true;
      committia.enable = true;
    };
  };
}
