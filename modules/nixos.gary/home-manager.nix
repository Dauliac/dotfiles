# Home-manager configuration for gary host
# Passes NixOS-level config (like services) to home-manager
{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (
      { config, ... }:
      let
        cfg = config.dotfiles.gary;
        enabledServices = lib.filterAttrs (_: svc: svc.enable) cfg.services;
      in
      {
        home-manager.users.gary = {
          home.stateVersion = "25.05";

          # Pass NixOS services to Firefox bookmarks
          dotfiles.gary.firefox = {
            enable = true;
            localServices = enabledServices;
            domain = if cfg.acme.enable then cfg.domain.public else cfg.domain.local;
            useTLS = cfg.acme.enable;
            scale = "3"; # HiDPI scaling
          };
        };

        home-manager.users.dauliac = {
          home.stateVersion = "25.05";
        };
      }
    )
  ];
}
