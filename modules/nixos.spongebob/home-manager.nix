{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.spongebob = lib.mkAfter [
    (
      { config, ... }:
      {
        home-manager = {
          useGlobalPkgs = true;
          users.dauliac = {
            imports =
              config.dotfiles.home.externalModules
              ++ config.dotfiles.home.sharedModules
              ++ (config.dotfiles.home.userModules.dauliac or [ ]);
          };
        };
      }
    )
  ];
}
