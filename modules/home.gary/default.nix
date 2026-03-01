# Home-manager configuration for user: gary
# Auto-imported by import-tree - no imports needed
# User-specific modules are in: firefox.nix, gnome.nix, packages.nix
{ lib, ... }:
{
  config.dotfiles.home.userModules.gary = lib.mkBefore [
    (
      { proprietaryEnabled, ... }:
      {
        services.flatpak = {
          enable = true;
          packages = lib.optionals proprietaryEnabled [
            {
              appId = "com.google.Chrome";
              origin = "flathub";
            }
          ];
        };
      }
    )
  ];
}
