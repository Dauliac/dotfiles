{ pkgs, ... }:
let
  cli = with pkgs; [
    go-task
    ghq
    sops
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
    gptcommit
    nerd-fonts.iosevka
    yt-dlp
    git-absorb
    git-gamble
    convco
    unzip
    comma
    claude-code
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
    vesktop
    protonvpn-gui
    proton-pass
  ];
in
{
  home.packages = cli ++ gui ++ tui;
}
