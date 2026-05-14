{
  flake.modules.homeManager.ghostty = {
    programs.ghostty = {
      enable = false;
      enableZshIntegration = true;
      systemd.enable = true;
      settings = {
        # font and colors managed by stylix
        selection-clear-on-copy = true;
        window-decoration = false;
      };
    };
  };
}
