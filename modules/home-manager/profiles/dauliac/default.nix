{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../desktop
  ];
  xdg.mime.enable = true;
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
      moonlight-qt
      brillo
      cava
      ffmpeg_4-full.bin
      termusic
      system76-firmware
      rclone
      vesktop
      ncpamixer
      pavucontrol
      pulsemixer
      whatsie
      gparted
      xdg-desktop-portal
      xdg-desktop-portal-gtk
      libreoffice
      google-chrome
    ]
    ++ music
    ++ videoGames;
}
