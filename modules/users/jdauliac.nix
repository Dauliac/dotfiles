{ config, pkgs, ... }: {
  imports = [ ../configs/default.nix ];
  home.username = "jdauliac";
  home.homeDirectory = "/home/${config.home.username}/";
  targets.genericLinux.enable = true;
}
