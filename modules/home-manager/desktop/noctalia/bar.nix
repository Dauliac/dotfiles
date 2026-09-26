{
  # v5 bar composition. See example.toml [bar.main]:
  #   - margin_ends = margin_edge = 0 and radius = 0 → full-screen-width strip.
  #   - start drops "wallpaper" (still reachable via /wall in the launcher).
  #   - end drops both "notifications" and "control-center" — the clock in
  #     the center already opens the notification center, so the right-side
  #     buttons were duplicates.
  flake.modules.homeManager.noctalia = {
    programs.noctalia.settings.bar.main = {
      position = "top";
      thickness = 34;
      background_opacity = 1.0;
      radius = 0;
      margin_ends = 0;
      margin_edge = 0;
      padding = 14;
      widget_spacing = 6;
      scale = 1.0;
      shadow = false;
      auto_hide = false;
      reserve_space = true;
      capsule = false;

      # Plugin widgets are placed by instance name; their `type = "<plugin>:<entry>"`
      # binding lives in `programs.noctalia.settings.widget.<name>` below (docs:
      # noctalia-shell/docs/user/plugins/index.mdx — "configure one by hand with
      # type = <author>/<plugin>:<entry>").
      start = [
        "launcher"
        "workspaces"
        "bongocat"
      ];
      center = [ "clock" ];
      end = [
        "claude_pulse"
        "media"
        "tray"
        "clipboard"
        "network"
        "bluetooth"
        "volume"
        "brightness"
        "battery"
        "session"
      ];
    };

    programs.noctalia.settings.widget = {
      bongocat.type = "noctalia/bongocat:cat";
      claude_pulse.type = "lowcache/claude-companion:pulse";
    };
  };
}
