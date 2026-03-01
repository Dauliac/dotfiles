# NixOS configuration for host: spongebob
# Auto-imported by import-tree - no imports needed
{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.spongebob = lib.mkAfter [
    (_: {
      networking.hostName = "spongebob";

      fileSystems."/data" = {
        device = "/dev/disk/by-label/data";
        fsType = "ext4";
        options = [ "noatime" ];
      };
    })
  ];
}
