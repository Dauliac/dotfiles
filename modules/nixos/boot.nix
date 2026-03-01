{ lib, ... }:
{
  config.dotfiles.nixos.sharedModules = lib.mkAfter [
    (
      { pkgs, ... }:
      {
        boot = {
          kernelPackages = pkgs.linuxPackages_latest;
          #plymouth.enable = true;
          #loader.systemd-boot.configurationLimit = 5;
          # NOTE: cross platform compilation for raspberry pi
          binfmt.emulatedSystems = [ "aarch64-linux" ];
        };
      }
    )
  ];
}
