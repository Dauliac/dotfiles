{ inputs, pkgs, ... }:
let
  cli = with pkgs; [
    go-task
    ghq
    glow
    silver-searcher # search
    ncdu # du alternative
    duf # df alternative
    fd # find alternative
    viddy # watch alternative
    gping # ping alternative
    procs # ps alternative
    hyperfine # benchmarking
    dog # dig alternative
    trash-cli # shell trash
    systemctl-tui # Cool tui
    speedtest-go # network speed test
    eza # TODO: check how to upgrade home-manager to use eza configs
    (nerdfonts.override { fonts = [ "FiraMono" ]; })
  ];
  gui = with pkgs; [
    sniffnet
    signal-desktop # Signal client
    # TODO: fix unfree packages
    # rustdesk # Remote desktop
    brave # Brave browser
    firefox-devedition # Firefox browser
  ];
in cli ++ gui
