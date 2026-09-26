{
  # Opt into the two default plugin sources noctalia clones on demand
  # (github.com/noctalia-dev/{official,community}-plugins — see
  # src/config/config_types.cpp defaultPluginSources).
  #
  # Catalog gaps as of research date:
  #   - no true emoji picker plugin exists (kaomoji is the closest).
  #   - no clipboard-history plugin exists; the cliphist user service in
  #     niri/session.nix still records history, but there's no picker —
  #     shell fallback `cliphist list | cliphist decode | wl-copy`.
  flake.modules.homeManager.noctalia = {
    programs.noctalia.settings.plugins = {
      auto_update = true;
      enabled = [
        # Bar widgets
        "noctalia/bongocat"           # cat animating with keystrokes (bar widget "cat")
        "lowcache/claude-companion"   # Claude Code attention pulse (bar widget "pulse")

        # QoL launcher extensions
        "noctalia/translator"         # /tr <text> — Google Translate
        "noctalia/kaomoji"            # /kao — kaomoji picker
        "cleboost/ssh-launcher"       # /ssh <host> from ~/.ssh/config
        "weinguyen/shell-command"     # /sh <cmd> — result in default terminal
      ];
    };
  };
}
