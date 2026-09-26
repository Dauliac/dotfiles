{
  flake.modules.homeManager.neovim = {
    home.sessionVariables = {
      VISUAL = "nvim";
    };
    programs.nixvim = {
      enable = true;
    };
  };
}
