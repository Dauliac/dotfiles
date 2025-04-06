{ pkgs, ... }:
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
    age # encryption
    eza # TODO: check how to upgrade home-manager to use eza configs
    yazi # file manager
    gptcommit
    # nerd-fonts.iosevka
    (nerdfonts.override {
      fonts = [
        "FiraMono"
        "Iosevka"
      ];
    })
    yt-dlp
    git-absorb
    git-gamble
    convco
    unzip
    comma
  ];
  tui = with pkgs; [
    bluetuith
    pulsemixer
  ];
  gui = with pkgs; [
    sniffnet
    # TODO: add override if we are in nixOs profile Signal client
    signal-desktop
    # TODO: fix unfree packages
    # rustdesk # Remote desktop
    # TODO: only install if we are not in nixOs profile
    # firefox-devedition # Firefox browser
    system76-keyboard-configurator
    protonvpn-gui
    proton-pass
  ];
in
{
  home.packages = cli ++ gui ++ tui;
}
