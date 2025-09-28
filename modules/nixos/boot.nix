{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    plymouth.enable = true;
    loader.systemd-boot.configurationLimit = 5;
    initrd.systemd.enable = true;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    bootspec.enable = true;
    # NOTE: cross platform compilation for raspberry pi
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
}
