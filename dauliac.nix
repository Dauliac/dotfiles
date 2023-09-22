{ config
, pkgs
, ...
}: {
  imports = [ ./common.nix ];
  home.username = "dauliac";
  home.homeDirectory = "/home/${config.home.username}/";
}
