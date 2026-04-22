{
  flake.modules.homeManager.yazi = {
    programs.yazi = {
      enable = true;
      settings.manager.show_hidden = true;
    };
  };
}
