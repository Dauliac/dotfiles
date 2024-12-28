{
  pkgs,
  lib,
  ...
}: {
  boot = {
    # kernelPackages = pkgs.linuxPackages_hardened;
    kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
    plymouth = {
      enable = true;
      themePackages = [(pkgs.catppuccin-plymouth.override {variant = "mocha";})];
      theme = "catppuccin-mocha";
    };
    initrd.systemd.enable = true;
    loader.systemd-boot.enable = lib.mkForce false;
    loader.systemd-boot.configurationLimit = 5;
    loader.efi.canTouchEfiVariables = true;
    bootspec.enable = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    # NOTE: cross platform compilation for raspberry pi
    binfmt.emulatedSystems = ["aarch64-linux"];
  };
}
