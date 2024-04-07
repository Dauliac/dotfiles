{config, ...}: {
  xdg.enable = true;
  xdg.mime.enable = false; # WARN: set it to true segfault nautilus
  xdg.systemDirs.data = ["${config.home.homeDirectory}/.nix-profile/share"];
}
