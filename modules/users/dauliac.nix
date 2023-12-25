{ config, pkgs, nixgl, ... }: {
  imports = [
    ../configs/default.nix
    { nixgl }
      ];
      home.username = "dauliac";
      home.homeDirectory = "/home/${config.home.username}/";
      }
