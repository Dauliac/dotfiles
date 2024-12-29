{ pkgs, ... }:
{
  home.shellAliases = {
    cat = "${pkgs.bat}/bin/bat";
    clip = "xclip -selection c";
    restore = "trash-restore";
    rm = "trash-put";
    watch = "${pkgs.viddy}/bin/viddy";
    ping = "${pkgs.gping}/bin/gping";
    ls = "${pkgs.eza}/bin/eza";
    cd = "z";
    ll = "ls -la";
    tree = "${pkgs.eza}/bin/eza --tree";
    ps = "${pkgs.procs}/bin/procs";
    df = "${pkgs.duf}/bin/duf";
    du = "${pkgs.ncdu}/bin/ncdu";
    work = "cd $(${pkgs.ghq}/bin/ghq root)/$(${pkgs.ghq}/bin/ghq list | fzf)";
    speedtest = "${pkgs.speedtest-go}/bin/peedtest-go";
    commit = "${pkgs.convco}/bin/convco commit";
  };
}
