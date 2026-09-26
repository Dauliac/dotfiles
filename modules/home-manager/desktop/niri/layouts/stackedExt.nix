{
  # `stackedExt` — external AOC 27B3HA2 stacked directly above the laptop
  # panel (both 1920 wide, so they align at x=640; external on top).
  #
  # Outputs are keyed by EDID identity ("Make Model Serial") rather than
  # connector name so the config survives cable/port swaps — `DP-2` /
  # `eDP-1` are just transient connector slots.
  flake.modules.homeManager.niri =
    { config, lib, ... }:
    lib.mkIf (config.myNiri.deskSetup == "stackedExt") {
      programs.niri.settings.outputs = {
        # AOC 27B3HA2 — serial-tagged, unique per panel.
        "PNP(AOC) 27B3HA2 AUEQ89A012276" = {
          enable = true;
          mode = {
            width = 1920;
            height = 1080;
          };
          scale = 1.0;
          position = {
            x = 640;
            y = 0;
          };
        };
        # ThinkPad P16s built-in panel — EDID has no serial, but the
        # make+model pair is unique among panels we own.
        "Lenovo Group Limited 0x403A Unknown" = {
          enable = true;
          mode = {
            width = 1920;
            height = 1200;
          };
          scale = 1.0;
          position = {
            x = 640;
            y = 1080;
          };
        };
      };
    };
}
