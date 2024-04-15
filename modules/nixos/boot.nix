{
  pkgs,
  inputs,
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
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    # TODO: Choose which kernel to use
    # boot.kernelPackages = pkgs.linuxPackages_hardened;
    bootspec.enable = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    # NOTE: cross platform compilation for raspberry pi
    binfmt.emulatedSystems = ["aarch64-linux"];
  };
}
