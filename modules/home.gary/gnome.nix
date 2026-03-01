# Home-manager niri/noctalia configuration for user: gary
{ lib, ... }:
{
  config.dotfiles.home.userModules.gary = lib.mkAfter [
    (
      _:
      {
        # noctalia-shell is already enabled in shared modules
        # (modules/home-manager/desktop/niri/default.nix)
        # Add any gary-specific niri/noctalia overrides here if needed
      }
    )
  ];
}
