{ pkgs, ... }: {
  cat = "${pkgs.bat}/bin/bat";
  nvim =
    "nix run $(${pkgs.ghq}/bin/ghq root)/$(${pkgs.ghq}/bin/ghq list | grep Dauliac/neovim)";
  clip = "xclip -selection c";
  restore = "trash-restore";
  rm = "trash-put";
  watch = "${pkgs.viddy}/bin/viddy";
  ping = "${pkgs.gping}/bin/gping";
  ls = "${pkgs.eza}/bin/eza";
  ll = "ls -la";
  tree = "${pkgs.eza}/bin/eza --tree";
  ps = "${pkgs.procs}/bin/procs";
  c = "clear";
  df = "${pkgs.duf}/bin/duf";
  du = "${pkgs.ncdu}/bin/ncdu";
  work = "cd $(${pkgs.ghq}/bin/ghq root)/$(${pkgs.ghq}/bin/ghq list | fzf)";
  speedtest = "${pkgs.peedtest-go}/bin/peedtest-go";
}
