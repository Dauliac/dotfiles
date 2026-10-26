{
  # v5 bar composition. See example.toml [bar.main]:
  #   - margin_ends = margin_edge = 0 and radius = 0 → full-screen-width strip.
  #   - start drops "wallpaper" (still reachable via /wall in the launcher).
  #   - end drops both "notifications" and "control-center" — the clock in
  #     the center already opens the notification center, so the right-side
  #     buttons were duplicates.
  flake.modules.homeManager.noctalia = { config, ... }:
    let
      # Fall back to the pre-abstraction literals when no host wires the
      # display aspect, so this module stays self-contained.
      display = config.systemConstants.display or {
        scale = 1.0;
        bar = {
          thickness = 34;
          padding = 14;
          widgetSpacing = 6;
        };
      };
    in {
    programs.noctalia.settings.bar.main = {
      position = "top";
      thickness = display.bar.thickness;
      background_opacity = 1.0;
      radius = 0;
      margin_ends = 0;
      margin_edge = 0;
      padding = display.bar.padding;
      widget_spacing = display.bar.widgetSpacing;
      scale = display.scale;
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
      # Bongocat plugin  -  slaps paws on typing AND flashes colors on audio
      # beats. Settings nest inline under [widget.<instance>] (not
      # [plugin_settings.*]) per the plugin.toml's [[widget.setting]]
      # schema (noctalia-dev/official-plugins/bongocat/plugin.toml).
      #
      # input_devices: evdev paths/globs to watch. by-id is stable across
      # reboots; the eventN numbers in /dev/input/eventN rotate. The glob
      # catches every keyboard present on the host (internal + any USB
      # keyboard you plug in later) without per-host hardcoding. If you
      # want the cat to also react to mouse clicks, extend the list with
      # "/dev/input/by-id/*-event-mouse".
      #
      # Runtime requirements (declared per host):
      #   - evtest on PATH (apt on Debian / nixpkgs on NixOS)
      #   - user is a member of the `input` group (read access to
      #     /dev/input/event*)
      # Without either, the widget still renders but never animates on
      # typing  -  exactly the current manomano symptom.
      #
      # audio_spectrum = true gates tappy_mode + rave_mode (visible_when
      # in plugin.toml). rave_mode flashes the cat colors on detected
      # PipeWire beats; tappy_mode makes paws tap to beats even when
      # nothing is being typed. use_mpris_filter is left false so the
      # cat reacts to ANY PipeWire output (system sounds, browser audio,
      # cava, etc.), not just the active MPRIS player.
      bongocat = {
        type = "noctalia/bongocat:cat";
        input_devices = [ "/dev/input/by-id/*-event-kbd" ];
        audio_spectrum = true;
        tappy_mode = true;
        rave_mode = true;
      };
    };
  };
}
