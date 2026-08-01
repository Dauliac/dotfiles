{
  flake.modules.homeManager.aliases = { pkgs, ... }: {
    home.shellAliases = {
      cat = "${pkgs.bat}/bin/bat";
      clip = "xclip -selection c";
      restore = "trash-restore";
      rm = "trash-put";
      watch = "${pkgs.viddy}/bin/viddy";
      ping = "${pkgs.gping}/bin/gping";
      cd = "z";
      ll = "ls -la";
      ps = "${pkgs.procs}/bin/procs";
      df = "${pkgs.duf}/bin/duf";
      du = "${pkgs.ncdu}/bin/ncdu";
      work = "cd $(${pkgs.ghq}/bin/ghq root)/$(${pkgs.ghq}/bin/ghq list | fzf)";
      speedtest = "${pkgs.speedtest-go}/bin/peedtest-go";
      commit = "${pkgs.convco}/bin/convco commit";
      tree = "${pkgs.eza}/bin/eza -T";
      history = "${pkgs.mcfly}/bin/mcfly dump | ${pkgs.jq}/bin/jq";
      # Coding-agent tooling — short aliases for common invocations
      # (beads-viewer ships the `bv` binary directly, no alias needed)
      ccd = "${pkgs.ccusage}/bin/ccusage claude daily";
      ccm = "${pkgs.ccusage}/bin/ccusage claude monthly";
      ccb = "${pkgs.ccusage}/bin/ccusage claude blocks";
      # Opt-in multiplexer: `tm` attaches/creates the "main" tmux session.
      # (Auto-attach on shell start was removed 2026-08-01 so herdr and
      # other agent multiplexers can run in a plain shell.)
      tm = "${pkgs.tmux}/bin/tmux new-session -A -s main";
    };
  };
}
