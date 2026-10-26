{
  # gary bind divergences on top of the shared base at
  # modules/home-manager/desktop/niri/binds/common.nix + azerty.nix +
  # qwerty.nix. Everything the TV box agrees with the laptop on
  # (focus arrows + hjkl, media keys to noctalia, overview/close/etc.)
  # inherits from the base; this file only re-defines the handful of
  # binds gary actively diverges on.
  #
  # Rules of thumb:
  #   - mkForce on binds the base also declares to the same key
  #   - plain assignment on binds the base does not touch
  #   - keep intent minimal, do not re-declare matching binds
  flake.modules.homeManager.user-gary =
    { lib, ... }:
    {
      programs.niri.settings.binds = {
        # TV-browser: chromium instead of zen.
        "Mod+B" = lib.mkForce {
          hotkey-overlay.title = "Open a Browser (chromium)";
          action.spawn = "chromium";
        };

        # Launcher: no noctalia panel on gary, use wofi directly.
        "Mod+D" = lib.mkForce {
          hotkey-overlay.title = "Run an Application";
          action.spawn-sh = "wofi --show drun";
        };

        # TV volume/media keys bypass noctalia (not installed on gary's
        # TV session) and talk straight to wpctl / playerctl.
        "XF86AudioRaiseVolume" = lib.mkForce {
          allow-when-locked = true;
          action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+";
        };
        "XF86AudioLowerVolume" = lib.mkForce {
          allow-when-locked = true;
          action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-";
        };
        "XF86AudioMute" = lib.mkForce {
          allow-when-locked = true;
          action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };
        "XF86AudioPlay" = lib.mkForce {
          allow-when-locked = true;
          action.spawn-sh = "playerctl play-pause";
        };
        "XF86AudioNext" = lib.mkForce {
          allow-when-locked = true;
          action.spawn-sh = "playerctl next";
        };
        "XF86AudioPrev" = lib.mkForce {
          allow-when-locked = true;
          action.spawn-sh = "playerctl previous";
        };
        "XF86AudioStop" = lib.mkForce {
          allow-when-locked = true;
          action.spawn-sh = "playerctl stop";
        };

        # Digit-row workspace jump: inherits Mod+1..9 from
        # ../../home-manager/desktop/niri/binds/qwerty.nix. gary gets
        # that via the US layout set in ./input.nix.
      };
    };
}
