{ ... }: {
  imports = [
    ../desktop
  ];
  xdg.mime.enable = true;
  home.activation.setupEtc = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    /run/current-system/sw/bin/systemctl start --user sops-nix
  '';
}
