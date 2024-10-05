{
  pkgs,
  lib,
  ...
}: {
  boot = {
    plymouth = {
      enable = true;
      themePackages = [(pkgs.catppuccin-plymouth.override {variant = "mocha";})];
      theme = "catppuccin-mocha";
    };
    initrd.systemd.enable = true;
    loader.systemd-boot.enable = lib.mkForce false;
    loader.systemd-boot.configurationLimit = 5;
    loader.efi.canTouchEfiVariables = true;
    # TODO: Choose which kernel to use
    # kernelPackages = pkgs.linuxPackages_xanmod_latest;
    # boot.kernelPackages = pkgs.linuxPackages_hardened;
    # boot.kernelPackages = pkgs.linuxPackages_6_8;
    bootspec.enable = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    # NOTE: cross platform compilation for raspberry pi
    binfmt.emulatedSystems = ["aarch64-linux"];
  };
}
