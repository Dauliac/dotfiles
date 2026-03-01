# NixOS configuration for host: gary
# Auto-imported by import-tree - no imports needed
{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (_: {
      networking.hostName = "gary";
    })
  ];
}
