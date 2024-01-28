{ config, pkgs, nixgl, ... }: {
  imports = [ ../configs/default.nix ];
  home.username = "dauliac";
  home.homeDirectory = "/home/${config.home.username}/";
  targets.genericLinux.enable = true;
}
