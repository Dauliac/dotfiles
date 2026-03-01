# Home-manager base configuration - auto-imported by import-tree
# No imports needed - other modules are automatically discovered
{ lib, ... }:
let
  xdgConfigDir = ./xdg-config;
in
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (
      { config, ... }:
      {
        home.stateVersion = "25.05";
        home.enableNixpkgsReleaseCheck = false;
        home.file."${config.xdg.configHome}" = {
          source = xdgConfigDir;
          recursive = true;
        };
        fonts.fontconfig.enable = true;
        # Enable XDG integration for desktop entries and icons
        xdg.enable = true;
        xdg.mime.enable = true;
        xdg.mimeApps.enable = true;
        # Force overwrite existing mimeapps.list
        xdg.configFile."mimeapps.list".force = true;
        # Include nix-profile in XDG data dirs for GNOME to find desktop files and icons
        xdg.systemDirs.data = [
          "${config.home.profileDirectory}/share"
          "/nix/var/nix/profiles/default/share"
        ];
        home.sessionVariables = {
          BROWSER = "zen";
        };
      }
    )
  ];
}
