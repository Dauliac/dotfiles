{ config, ... }: {
  # WARN: set it to true segfault nautilus in non nixOs systems
  xdg.mime.enable = false;
  xdg.systemDirs.data = [ "${config.home.homeDirectory}/.nix-profile/share" ];
  home.activation.setupEtc = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    /usr/bin/systemctl start --user sops-nix
  '';
}
