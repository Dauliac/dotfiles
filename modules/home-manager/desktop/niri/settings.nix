{
  # Non-bind, non-startup settings.  Split by concern into let-blocks so the
  # module stays readable even though it lives in one file (medium-dendritic).
  flake.modules.homeManager.niri = {
    programs.niri.settings = {
      # ── Input ────────────────────────────────────────────────────────────
      input = {
        keyboard.xkb = {
          # French AZERTY (latin9) — matches /etc/default/keyboard on the
          # ThinkPads (ML-PF59GCGW, ML-PF603JJ8). Wayland compositors don't
          # read /etc/default/keyboard, so we set xkb explicitly here.
          # us + es kept as secondary layouts, toggle with Super+Space.
          layout = "fr,us,es";
          variant = "latin9,,";
          # Compose must NOT be on ralt: that steals AltGr and kills
          # AltGr+à (@), AltGr+é (~), AltGr+è (`), etc. on fr(latin9).
          options = "grp:win_space_toggle,compose:menu,ctrl:nocaps";
        };
        keyboard.numlock = true;
        touchpad = {
          tap = true;
          natural-scroll = true;
        };
      };

      # ── Outputs ──────────────────────────────────────────────────────────
      # Per-desk `outputs` blocks live in ./layouts/*.nix, gated on the
      # `myNiri.deskSetup` enum (declared in ./options.nix). Each layout
      # keys outputs by EDID identity ("Make Model Serial") so config
      # survives cable/port swaps.

      # ── Overview ─────────────────────────────────────────────────────────
      overview.zoom = 0.45;

      # ── Layout / Decorations ─────────────────────────────────────────────
      layout = {
        gaps = 5;
        center-focused-column = "on-overflow";
        always-center-single-column = true;

        focus-ring = {
          enable = false;
          width = 2;
          active.color = "#7fc8ff";
          inactive.color = "#505050";
        };

        border = {
          enable = false;
          width = 2;
          active.color = "#ffc87f";
          inactive.color = "#505050";
          urgent.color = "#9b0000";
        };

        shadow = {
          enable = true;
          draw-behind-window = true;
          softness = 50;
          spread = 5;
          offset = {
            x = 0;
            y = 5;
          };
          color = "#0007";
        };

        background-color = "transparent";
      };

      # ── Misc top-level ───────────────────────────────────────────────────
      hotkey-overlay.skip-at-startup = true;
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      # ── Named workspaces (persistent, ordered by key) ────────────────────
      workspaces = {
        "01" = {
          name = "1";
        };
        "02" = {
          name = "brow";
        };
        "03" = {
          name = "term";
        };
        "04" = {
          name = "4";
        };
        "05" = {
          name = "5";
        };
        "06" = {
          name = "6";
        };
        "07" = {
          name = "7";
        };
        "08" = {
          name = "obs";
        };
        "09" = {
          name = "oss";
        };
      };

      # ── Window rules ─────────────────────────────────────────────────────
      window-rules = [
        {
          matches = [ { app-id = ''^org\.wezfurlong\.wezterm$''; } ];
          default-column-width = { };
        }
        {
          matches = [ { title = "Picture in picture"; } ];
          open-floating = true;
          default-floating-position = {
            x = 100;
            y = 100;
            relative-to = "bottom-right";
          };
          tiled-state = true;
        }
        {
          matches = [ { app-id = "obs"; } ];
          open-on-workspace = "obs";
        }
        {
          matches = [ { app-id = "steam"; } ];
          open-on-workspace = "oss";
        }
        {
          matches = [ { app-id = "^Spotify$"; } ];
          open-on-workspace = "oss";
        }
        {
          matches = [ { app-id = "^discord$"; } ];
          open-on-workspace = "oss";
        }
        {
          matches = [ { app-id = "chromium"; } ];
          open-maximized = true;
          open-on-workspace = "brow";
        }
        {
          matches = [ { app-id = "ghostty"; } ];
          open-maximized = true;
          open-on-workspace = "term";
        }
        # Global rule: rounded corners + clip to geometry for every window.
        {
          geometry-corner-radius = {
            top-left = 6.0;
            top-right = 6.0;
            bottom-left = 6.0;
            bottom-right = 6.0;
          };
          clip-to-geometry = true;
        }
      ];

      layer-rules = [
        {
          place-within-backdrop = true;
        }
      ];
    };
  };
}
