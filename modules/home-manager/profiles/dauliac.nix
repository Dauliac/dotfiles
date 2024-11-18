{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../desktop
  ];
  xdg.mime.enable = true;
  home.activation.setupEtc = config.lib.dag.entryAfter ["writeBoundary"] ''
    /run/current-system/sw/bin/systemctl start --user sops-nix
  '';
  home.packages =
  let
    music = with pkgs; [
      rosegarden
      ardour
      zam-plugins
      qpwgraph
      # bristol
    ];
  in
  with pkgs; [
    prismlauncher
    brillo
    cava
    ffmpeg_4-full.bin
    termusic
    sonic-pi
    system76-firmware
    rclone
    discord
    ncpamixer
    steam-tui
    steamcmd
    pavucontrol
    pulsemixer
  ] ++ music;
}
