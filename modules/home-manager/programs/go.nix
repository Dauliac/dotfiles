{
  flake.modules.homeManager.go = {
    programs.go = {
      enable = true;
      env.GOBIN = ".local/bin.go";
    };
  };
}
