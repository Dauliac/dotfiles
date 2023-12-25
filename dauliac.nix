{ config, pkgs, nixgl, ... }: {
  imports = [
    ./common.nix
    { nixgl } ];
    home.username = "dauliac";
    home.homeDirectory = "/home/${config.home.username}/";
    }
