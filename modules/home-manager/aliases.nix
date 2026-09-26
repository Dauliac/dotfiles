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
      ccd = "${pkgs.ccusage}/bin/ccusage claude daily";
      ccm = "${pkgs.ccusage}/bin/ccusage claude monthly";
      ccb = "${pkgs.ccusage}/bin/ccusage claude blocks";
      # `bv` (beads-viewer) is the graph-aware TUI for the shared Dolt-backed
      # beads DB. Replaces the earlier `mg` (mardi-gras) alias — see openspec
      # change beads-go-migration-and-dolt-caps.
      bv = "${pkgs.beads-viewer}/bin/bv";
      # `mg` (mardi-gras) restored alongside `bv` per openspec change
      # beads-mg-tui-integration. mg reads .beads/issues.jsonl (the passive
      # export of the Dolt-backed beads DB), so we flush it first via
      # `bd sync --flush-only` — otherwise mg shows stale issue state.
      mg = "${pkgs.beads}/bin/bd sync --flush-only && ${pkgs.mardi-gras}/bin/mg";
      # Opt-in multiplexer: `tm` attaches/creates the "main" tmux session.
      # (Auto-attach on shell start was removed 2026-08-01 so herdr and
      # other agent multiplexers can run in a plain shell.)
      tm = "${pkgs.tmux}/bin/tmux new-session -A -s main";
    };
  };
}
