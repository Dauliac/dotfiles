{
  inputs,
  pkgs,
  config,
  osConfig,
  lib,
  ...
}:
let
  screenshotarea = "hyprctl keyword animation 'fadeOut,0,0,default'; ${pkgs.grimblast}/bin/grimblast --notify copysave area; hyprctl keyword animation 'fadeOut,1,4,default'";
  # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
  workspaces = builtins.concatLists (
    builtins.genList (
      x:
      let
        ws =
          let
            c = (x + 1) / 10;
          in
          builtins.toString (x + 1 - (c * 10));
      in
      [
        "$mod, ${ws}, workspace, ${toString (x + 1)}"
        "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
      ]
    ) 10
  );
in
{
  wayland = {
    windowManager.hyprland = {
      enable = true;
      settings = {
        "$mod" = "SUPER";
        monitor =
          let
            default = rec {
              description = "Chimei Innolux Corporation 0x1408";
              width = 1920;
              height = 1080;
              verticalPosition = 0;
              horizontalPosition = 0;
              positionConfig = builtins.toString horizontalPosition + "x" + builtins.toString verticalPosition;
              config = "desc:${description},preferred,${default.positionConfig},1";
            };
            topLarge = rec {
              description = "Beihai Century Joint Innovation Technology Co.Ltd CS2900";
              width = 2560;
              height = 1080;
              verticalPosition = -height;
              horizontalPosition = -(width - default.width);
              positionConfig = builtins.toString horizontalPosition + "x" + builtins.toString verticalPosition;
              config = "desc:${description},preferred,${topLarge.positionConfig},1";
            };
            leftVertical = rec {
              description = "Lenovo Group Limited LEN T24i-20 VNA4HXH3";
              width = 1080;
              height = 1920;
              verticalPosition = -topLarge.height;
              horizontalPosition = default.width;
              positionConfig =
                builtins.toString leftVertical.horizontalPosition
                + "x"
                + builtins.toString leftVertical.verticalPosition;
              config = "desc:${description},preferred,${leftVertical.positionConfig},1,transform,1";
            };
          in
          [
            default.config
            topLarge.config
            leftVertical.config
          ];
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
          "$mod ALT, mouse:272, resizewindow"
        ];
        bind =
          let
            monocle = "dwindle:no_gaps_when_only";
          in
          [
            # NOTE: compositor commands
            "$mod SHIFT, E, exec, pkill Hyprland"
            "$mod, Q, killactive,"
            # TODO: use firefox in firejail if nixOs profile is enabled
            # "$mod ,B,exec,${pkgs.firefox-devedition}/bin/firefox-devedition"
            "$mod ,B,exec,firefox-devedition"
            "$mod, f, fullscreen,"
            "$mod, G, togglegroup,"
            "$mod SHIFT, N, changegroupactive, f"
            "$mod SHIFT, P, changegroupactive, b"
            "$mod, R, togglesplit,"
            "$mod, T, togglefloating,"
            "$mod, P, pseudo,"
            "$mod ALT, ,resizeactive,"
            # terminal
            # "$mod, Return, exec, ${pkgs.wezterm}/bin/wezterm"
            "$mod, Return, exec, ${pkgs.rio}/bin/rio"
            # logout menu
            "$mod, Escape, exec, wlogout -p layer-shell"
            # lock screen
            "$mod, L, exec, loginctl lock-session"
            # select area to perform OCR on
            # "$mod, O, exec, run-as-service wl-ocr"
            # move focus
            "$mod, left, movefocus, l"
            "$mod, right, movefocus, r"
            "$mod, up, movefocus, u"
            "$mod, down, movefocus, d"
            "$mod, h, movefocus, l"
            "$mod, l, movefocus, r"
            "$mod, k, movefocus, u"
            "$mod, j, movefocus, d"
            # screenshot
            # stop animations while screenshotting; makes black border go away
            ", Print, exec, ${screenshotarea}"
            # special workspace
            "$mod SHIFT, grave, movetoworkspace, special"
            "$mod, grave, togglespecialworkspace, eDP-1"
            # cycle workspaces
            "$mod, bracketleft, workspace, m-1"
            "$mod, bracketright, workspace, m+1"
            # cycle monitors
            "$mod SHIFT, bracketleft, focusmonitor, l"
            "$mod SHIFT, bracketright, focusmonitor, r"
            # send focused workspace to left/right monitors
            "$mod SHIFT ALT, bracketleft, movecurrentworkspacetomonitor, l"
            "$mod SHIFT ALT, bracketright, movecurrentworkspacetomonitor, r"
          ]
          ++ workspaces;

        bindr = [
          # NOTE: launcher
          "$mod, r, exec, ${config.programs.rofi.package}/bin/rofi -show drun"
          "$mod, w, exec, ${config.programs.rofi.package}/bin/rofi -show window"
        ];

        bindl = [
          # NOTE: media controls
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
          ", XF86AudioNext, exec, playerctl next"
          # NOTE: volume
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ];

        bindle = [
          # NOTE: volume
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%-"
          # NOTE: backlight
          ", XF86MonBrightnessUp, exec, brillo -q -u 300000 -A 5"
          ", XF86MonBrightnessDown, exec, brillo -q -u 300000 -U 5"
        ];
      };
    };
  };
}
