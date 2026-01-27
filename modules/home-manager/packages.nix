{ pkgs, ... }:
let
  ai = with pkgs; [
    claude-code
    codemap
    codemap-mcp
    anytype-cli
  ];
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
    nerd-fonts.iosevka
    yt-dlp
    git-absorb
    git-gamble
    convco
    unzip
    comma
    postgresql_16
    pgcli
    asdf
    jless
    skaffold
    atlas
    clickhouse
    entr
    cargo-tarpaulin
    (pkgs.wrapHelm pkgs.kubernetes-helm {
      plugins = [
        pkgs.kubernetes-helmPlugins.helm-diff
        pkgs.kubernetes-helmPlugins.helm-secrets
      ];
    })
  ];
  tui = with pkgs; [
    bluetuith
    pulsemixer
    stu
  ];
  gui = with pkgs; [
    sniffnet
    # TODO: add override if we are in nixOs profile Signal client
    # TODO: fix unfree packages
    # rustdesk # Remote desktop
    # TODO: only install if we are not in nixOs profile
    # firefox-devedition # Firefox browser
    system76-keyboard-configurator
    protonvpn-gui
    proton-pass
    discord
  ];
in
{
  home.packages = cli ++ gui ++ tui ++ ai;
}
