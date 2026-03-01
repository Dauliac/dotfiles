{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (_: {
      gtk = {
        # enable = true;
        # font = {
        #  name = "Iosevka";
        #  size = 9;
        # };
      };
    })
  ];
}
