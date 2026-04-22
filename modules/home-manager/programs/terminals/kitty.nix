{
  flake.modules.homeManager.kitty = {
    programs.kitty = {
      enable = true;
      shellIntegration.enableZshIntegration = true;
    };
  };
}
