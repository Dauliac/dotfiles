{
  # Layout-agnostic keybinds — everything that doesn't touch the digit
  # row. The digit-row → workspace bindings live in ./azerty.nix (fr
  # keysyms) and ./qwerty.nix (us digits); both are imported alongside
  # this file so the same physical key emits the right action regardless
  # of the active xkb layout at the moment.
  #
  # niri-flake's schema:
  #   "<Key>" = { <optional bind props>; action.<name> = <value>; };
  # Zero-argument actions take `{}` as the value; spawn accepts a string
  # (single command) or a list of argv items. See docs.md in sodiboo/niri-flake.
  flake.modules.homeManager.niri = {
    programs.niri.settings.binds = {
      # ── Hotkey overlay / meta ──────────────────────────────────────────
      "Mod+Shift+Slash".action.show-hotkey-overlay = { };
      "Mod+Shift+O" = {
        repeat = false;
        hotkey-overlay.title = "toggle opacity";
        action.toggle-window-rule-opacity = { };
      };
      # ── App launchers ──────────────────────────────────────────────────
      "Mod+T" = {
        hotkey-overlay.title = "Open a Terminal";
        action.spawn = "ghostty";
      };
      "Mod+B" = {
        hotkey-overlay.title = "Open a Browser (zen)";
        action.spawn = "app.zen_browser.zen";
      };
      "Mod+D" = {
        hotkey-overlay.title = "Run an Application";
        action.spawn-sh = "noctalia msg panel-toggle launcher";
      };
      "Super+Shift+L" = {
        hotkey-overlay.title = "Lock the Screen";
        action.spawn-sh = "loginctl lock-session";
      };
      # ── Audio / brightness / media keys ────────────────────────────────
      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn-sh = "noctalia msg volume-up 5";
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn-sh = "noctalia msg volume-down 5";
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn-sh = "noctalia msg volume-mute";
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action.spawn-sh = "noctalia msg mic-mute";
      };
      "XF86AudioPlay" = {
        allow-when-locked = true;
        action.spawn-sh = "noctalia msg media toggle";
      };
      "XF86AudioNext" = {
        allow-when-locked = true;
        action.spawn-sh = "noctalia msg media next";
      };
      "XF86AudioPrev" = {
        allow-when-locked = true;
        action.spawn-sh = "noctalia msg media previous";
      };
      "XF86AudioStop" = {
        allow-when-locked = true;
        action.spawn-sh = "noctalia msg media stop";
      };
      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn-sh = "noctalia msg brightness-up all 10";
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn-sh = "noctalia msg brightness-down all 10";
      };
      "XF86KbdBrightnessUp" = {
        allow-when-locked = true;
        action.spawn-sh = "noctalia msg keyboard-backlight-up";
      };
      "XF86KbdBrightnessDown" = {
        allow-when-locked = true;
        action.spawn-sh = "noctalia msg keyboard-backlight-down";
      };
      "XF86KbdLightOnOff" = {
        allow-when-locked = true;
        action.spawn-sh = "noctalia msg keyboard-backlight-toggle";
      };

      # ── Overview / window management ───────────────────────────────────
      "Mod+TAB" = {
        repeat = false;
        action.toggle-overview = { };
      };
      "Mod+Q" = {
        repeat = false;
        action.close-window = { };
      };

      # ── Focus (arrows + hjkl) ──────────────────────────────────────────
      "Mod+Left".action.focus-column-left = { };
      "Mod+Down".action.focus-window-or-workspace-down = { };
      "Mod+Up".action.focus-window-or-workspace-up = { };
      "Mod+Right".action.focus-column-right = { };
      "Mod+H".action.focus-column-left = { };
      "Mod+L".action.focus-column-right = { };
      "Mod+J".action.focus-window-or-workspace-down = { };
      "Mod+K".action.focus-window-or-workspace-up = { };

      # ── Move (with Ctrl) ───────────────────────────────────────────────
      "Mod+Ctrl+Left".action.move-column-left = { };
      "Mod+Ctrl+Down".action.move-window-down = { };
      "Mod+Ctrl+Up".action.move-window-up = { };
      "Mod+Ctrl+Right".action.move-column-right = { };
      "Mod+Ctrl+H".action.move-column-left = { };
      "Mod+Ctrl+L".action.move-column-right = { };
      "Mod+Ctrl+J".action.move-window-down-or-to-workspace-down = { };
      "Mod+Ctrl+K".action.move-window-up-or-to-workspace-up = { };

      # ── Move column to adjacent monitor ────────────────────────────────
      "Mod+Shift+H".action.move-column-to-monitor-left = { };
      "Mod+Shift+L".action.move-column-to-monitor-right = { };
      "Mod+Shift+J".action.move-column-to-monitor-down = { };
      "Mod+Shift+K".action.move-column-to-monitor-up = { };

      # ── Focus adjacent monitor ─────────────────────────────────────────
      # Mirrors Mod+HJKL (focus window) and Mod+Shift+HJKL (move window
      # across monitors); Mod+Alt is the free slot in the modifier grid.
      "Mod+Alt+H".action.focus-monitor-left = { };
      "Mod+Alt+L".action.focus-monitor-right = { };
      "Mod+Alt+J".action.focus-monitor-down = { };
      "Mod+Alt+K".action.focus-monitor-up = { };

      # ── First/last column ──────────────────────────────────────────────
      "Mod+Home".action.focus-column-first = { };
      "Mod+End".action.focus-column-last = { };
      "Mod+Ctrl+Home".action.move-column-to-first = { };
      "Mod+Ctrl+End".action.move-column-to-last = { };

      # ── Workspace focus (non-digit) ────────────────────────────────────
      "Mod+Page_Down".action.focus-workspace-down = { };
      "Mod+Page_Up".action.focus-workspace-up = { };
      "Mod+U".action.focus-workspace-down = { };
      "Mod+I".action.focus-workspace-up = { };
      "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
      "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };
      "Mod+Ctrl+U".action.move-column-to-workspace-down = { };
      "Mod+Ctrl+I".action.move-column-to-workspace-up = { };
      "Mod+Shift+Page_Down".action.move-workspace-down = { };
      "Mod+Shift+Page_Up".action.move-workspace-up = { };
      "Mod+Shift+U".action.move-workspace-down = { };
      "Mod+Shift+I".action.move-workspace-up = { };

      # ── Wheel bindings ─────────────────────────────────────────────────
      "Mod+WheelScrollDown" = {
        cooldown-ms = 150;
        action.focus-workspace-down = { };
      };
      "Mod+WheelScrollUp" = {
        cooldown-ms = 150;
        action.focus-workspace-up = { };
      };
      "Mod+Ctrl+WheelScrollDown" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-down = { };
      };
      "Mod+Ctrl+WheelScrollUp" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-up = { };
      };
      "Mod+WheelScrollRight".action.focus-column-right = { };
      "Mod+WheelScrollLeft".action.focus-column-left = { };
      "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
      "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };
      "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
      "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
      "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
      "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

      # ── Column consume / expel ─────────────────────────────────────────
      "Mod+BracketLeft".action.consume-or-expel-window-left = { };
      "Mod+BracketRight".action.consume-or-expel-window-right = { };
      "Mod+Comma".action.consume-window-into-column = { };
      "Mod+Period".action.expel-window-from-column = { };

      # ── Sizing ─────────────────────────────────────────────────────────
      "Mod+R".action.switch-preset-column-width = { };
      "Mod+Shift+R".action.switch-preset-window-height = { };
      "Mod+Ctrl+R".action.reset-window-height = { };
      "Mod+F".action.maximize-column = { };
      "Mod+Shift+F".action.fullscreen-window = { };
      "Mod+Ctrl+F".action.expand-column-to-available-width = { };
      "Mod+C".action.center-column = { };
      "Mod+Ctrl+C".action.center-visible-columns = { };
      # Un-shifted `Mod+Minus` / `Mod+Equal` for column-width would
      # collide with azerty.nix's workspace-6 bind (`Mod+minus` — xkb
      # keysyms are case-insensitive so `Minus` ≡ `minus`, and niri
      # rejects duplicate binds at eval time). Sizing stays reachable
      # via `Mod+R` (preset column widths), `Mod+Ctrl+F` (expand), and
      # the shifted variants below. Add layout-scoped fine-tune binds
      # in qwerty.nix / azerty.nix if you miss them.
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";

      # ── Floating ───────────────────────────────────────────────────────
      "Mod+V".action.toggle-window-floating = { };
      "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = { };

      # ── Screenshot ─────────────────────────────────────────────────────
      "Print".action.screenshot = { };
      "Ctrl+Print".action.screenshot-screen = { };
      "Alt+Print".action.screenshot-window = { };
      "Shift+Print" = {
        hotkey-overlay.title = "Screenshot region → annotate (satty)";
        action.spawn-sh = "grim -g \"$(slurp)\" - | satty --filename - --output-filename ~/Pictures/$(date +%Y%m%d-%H%M%S).png --early-exit --copy-command wl-copy";
      };

      # ── Pickers / helpers ──────────────────────────────────────────────
      "Mod+Shift+C" = {
        hotkey-overlay.title = "Color picker (hyprpicker → clipboard)";
        action.spawn-sh = "hyprpicker --autocopy --format=hex";
      };

      # ── Noctalia panel toggles ─────────────────────────────────────────
      "Mod+N" = {
        hotkey-overlay.title = "Toggle notifications panel";
        action.spawn-sh = "noctalia msg panel-toggle control-center";
      };

      # ── Session control ────────────────────────────────────────────────
      "Mod+Escape" = {
        allow-inhibiting = false;
        action.toggle-keyboard-shortcuts-inhibit = { };
      };
      "Mod+Shift+E".action.quit = { };
      "Ctrl+Alt+Delete".action.quit = { };
      "Mod+Shift+P".action.power-off-monitors = { };
    };
  };
}
