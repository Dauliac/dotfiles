{
  # Noctalia's notification daemon. Section key is `notification` (singular),
  # not `notifications` — see src/config/config_types.h struct
  # NotificationConfig and src/config/schema/config_schema.cpp
  # `notificationSchema`.
  #
  # No global DND toggle — either flip `enable_daemon = false` for the whole
  # daemon, or use per-app filters (`show_toast = false`).
  # No global timeout / sound file — those are per-filter.
  flake.modules.homeManager.noctalia = {
    programs.noctalia.settings.notification = {
      enable_daemon = true;

      # Placement + look
      position = "top_right";
      layer = "top";
      scale = 1.0;
      background_opacity = 0.97;
      border = true;
      offset_x = 20;
      offset_y = 8;

      # Behavior
      show_app_name = true;
      show_actions = true;
      collapse_on_dismiss = true;
      max_visible = 5;                # 0 = unlimited (default) — cap keeps it sane
      history_retention_hours = 48;   # 0 = disabled (default) — 48h is one workweek edge

      # Per-app filters — cheap examples; extend as noise appears.
      # Each entry follows NotificationFilterConfig schema.
      filter = {
        # Slack: keep in history, no toast pop, no sound
        slack = {
          enabled = true;
          match = "slack";
          show_toast = false;
          save_history = true;
          play_sound = false;
        };
        # Discord (if used): same treatment
        discord = {
          enabled = true;
          match = "discord";
          show_toast = false;
          save_history = true;
          play_sound = false;
        };
        # auto-upgrade: security-upgrade summaries emitted by
        # modules/system-manager/auto-upgrade.nix. Keep the toast (urgency
        # `critical` matters for reboot-required) and persist to history.
        # Flip show_toast=false here if the daily "N upgrades applied"
        # ever becomes noise.
        auto-upgrade = {
          enabled = true;
          match = "auto-upgrade";
          show_toast = true;
          save_history = true;
          play_sound = false;
        };
      };
    };
  };
}
