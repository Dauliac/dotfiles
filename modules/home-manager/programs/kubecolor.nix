{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (_: {
      programs.kubecolor = {
        enable = true;
        enableAlias = true;
        # enableZshIntegration = true;
      };
    })
  ];
}
