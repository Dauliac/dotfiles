{
  flake.modules.homeManager.noctalia = {
    programs.noctalia-shell = {
      enable = true;
      systemd.enable = true;
    };
  };
}
