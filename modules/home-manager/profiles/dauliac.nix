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
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
      "audio/*" = [ "vlc.desktop" ];
      "x-scheme-handler/http" = "zen.desktop"; # Replace with the actual file name
      "x-scheme-handler/https" = "zen.desktop"; # Replace with the actual file name
      "text/html" = "zen.desktop";
    };
  };

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
      moonlight-embedded
      brillo
      cava
      ffmpeg_4-full.bin
      termusic
      sonic-pi
      system76-firmware
      rclone
      vencord
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
