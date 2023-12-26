{ config, pkgs }: {
  enable = true;
  mime.enable = false; # WARN: set it to true segfault nautilus
  systemDirs.data = [ "${config.home.homeDirectory}/.nix-profile/share" ];
}
