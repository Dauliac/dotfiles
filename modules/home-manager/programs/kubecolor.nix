{
  flake.modules.homeManager.kubecolor = {
    programs.kubecolor = {
      enable = true;
      enableAlias = true;
    };
  };
}
