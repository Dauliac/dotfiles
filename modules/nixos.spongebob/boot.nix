{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.spongebob = lib.mkAfter [
    (_: {
      boot = {
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
      };
    })
  ];
}
