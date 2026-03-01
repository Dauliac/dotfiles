{ lib, ... }:
{
  config.dotfiles.nixos.sharedModules = lib.mkAfter [
    (_: {
      services.comin = {
        enable = true;
        remotes = [
          {
            name = "origin";
            url = "https://github.com/dauliac/dotfiles.git";
            branches.main.name = "master";
          }
        ];
      };
    })
  ];
}
