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
  xdg.desktopEntries.appflowy = {
    name = "AppFlowy";
    exec = "${pkgs.appflowy}/bin/appflowy %U";
    icon = "${pkgs.appflowy}/share/icons/hicolor/256x256/apps/appflowy.png";
    categories = [ "Utility" ];
    mimeType = [ "x-scheme-handler/appflowy-flutter" ];
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
      # "image/png" = ["feh.desktop"];
      # "image/jpeg" = ["feh.desktop"];
      # "image/jpg" = ["feh.desktop"];
      # "image/gif" = ["feh.desktop"];
      # "image/bmp" = ["feh.desktop"];
      # "image/tiff" = ["feh.desktop"];
      # "image/webp" = ["feh.desktop"];
      # "application/pdf" = ["sioyek.desktop"];
      # "application/epub+zip" = ["com.github.johnfactotum.Foliate.desktop"];
      # "video/*" = ["vlc.desktop"];
      "audio/*" = [ "vlc.desktop" ];
      "x-scheme-handler/http" = "zen.desktop"; # Replace with the actual file name
      "x-scheme-handler/https" = "zen.desktop"; # Replace with the actual file name
      "text/html" = "zen.desktop";
    };

    associations.added = {
      "x-scheme-handler/appflowy-flutter" = "appflowy.desktop";
      "x-scheme-handler/appflowy" = "appflowy.desktop";
      "x-scheme-handler/appflowy-desktop" = "appflowy.desktop";
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
      rustdesk-flutter
      brillo
      cava
      ffmpeg_4-full.bin
      termusic
      appflowy
      sonic-pi
      system76-firmware
      rclone
      discord
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
