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
  home.packages = with pkgs; [
    prismlauncher
    brillo
    cava
    ffmpeg_4-full.bin
    termusic
    sonic-pi
    system76-firmware
    rclone
  ];
}
