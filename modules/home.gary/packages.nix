{ lib, ... }:
{
  config.dotfiles.home.userModules.gary = lib.mkAfter [
    (
      {
        pkgs,
        proprietaryEnabled,
        ...
      }:
      {
        home.packages =
          with pkgs;
          [
            k9s
            vlc
            prismlauncher
          ]
          ++ lib.optionals proprietaryEnabled [
            stremio
            ryubing
            shadps4
          ];
      }
    )
  ];
}
