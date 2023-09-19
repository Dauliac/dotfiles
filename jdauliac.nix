{ config
, pkgs
, ...
}: {
  imports = [ ./common.nix ];
  home.username = "jdauliac";
  home.homeDirectory = "/home/${config.home.username}/";
}
