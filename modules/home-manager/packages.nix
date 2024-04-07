{pkgs, ...}: let
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
    radicle-cli # Decentralized git
    age # encryption
    eza # TODO: check how to upgrade home-manager to use eza configs
    nil # Nix lsp
    (nerdfonts.override {fonts = ["FiraMono" "Iosevka"];})
  ];
  gui = with pkgs; [
    sniffnet
    # TODO: add override if we are in nixOs profile Signal client
    signal-desktop
    # TODO: fix unfree packages
    # rustdesk # Remote desktop
    # TODO: only install if we are not in nixOs profile
    # firefox-devedition # Firefox browser
    overskride # Bluetooth client
    system76-keyboard-configurator
    system76-firmware
  ];
in {
  home.packages = cli ++ gui;
}
