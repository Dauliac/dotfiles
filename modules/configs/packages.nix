{ pkgs, ... }: [
  pkgs.go-task
  pkgs.ghq
  pkgs.silver-searcher # search
  pkgs.ncdu # du alternative
  pkgs.duf # df alternative
  pkgs.fd # find alternative
  pkgs.viddy # watch alternative
  pkgs.gping # ping alternative
  pkgs.procs # ps alternative
  pkgs.hyperfine # benchmarking
  pkgs.dog # dig alternative
  pkgs.trash-cli # shell trash
  pkgs.systemctl-tui # Cool tui
  pkgs.speedtest-go # network speed test
  pkgs.eza # TODO: check how to upgrade home-manager to use eza configs
  (pkgs.nerdfonts.override { fonts = [ "FiraMono" ]; })
]
