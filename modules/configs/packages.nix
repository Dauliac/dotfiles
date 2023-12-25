{ pkgs, ... }:
with pkgs; [
  go-task
  ghq
  glow
  sniffnet
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
]
