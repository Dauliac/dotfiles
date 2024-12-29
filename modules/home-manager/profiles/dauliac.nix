{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../desktop
  ];
  xdg.mime.enable = true;
  home.activation.setupEtc = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    /run/current-system/sw/bin/systemctl start --user sops-nix
  '';
  home.packages =
    let
      music = with pkgs; [
        rosegarden
        ardour
        zam-plugins
        qpwgraph
        zam-plugins # NOTE: VST
        bespokesynth # NOTE: synth
        bristol # NOTE: synth
        chow-kick # NOTE: drum synth
        espeak # NOTE: speech synthesis
        geonkick # NOTE: drum synth
        industrializer # NOTE: drum synth
        vcv-rack # NOTE: modular synth
        cardinal # NOTE: modular synth
        drumkv1
        gnaural
        ChowKick
        drumgizmo
      ];
      videoGames = with pkgs; [
        steam-tui
        steamcmd
      ];
    in
    with pkgs;
    [
      prismlauncher
      rustdesk-flutter
      brillo
      cava
      ffmpeg_4-full.bin
      termusic
      sonic-pi
      system76-firmware
      rclone
      discord
      ncpamixer
      pavucontrol
      pulsemixer
      whatsie
    ]
    ++ music
    ++ videoGames;
}
