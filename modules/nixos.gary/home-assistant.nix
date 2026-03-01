# Home Assistant smart home automation
# Defines options AND implementation together
{ lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types mkIf mkAfter;
in
{
  # ════════════════════════════════════════════
  # OPTIONS
  # ════════════════════════════════════════════
  options.dotfiles.gary.homeAssistant = {
    enable = mkEnableOption "Home Assistant";

    timezone = mkOption {
      type = types.str;
      default = "Europe/Paris";
      description = "Timezone for Home Assistant";
    };

    homeName = mkOption {
      type = types.str;
      default = "Home";
      description = "Name of your home";
    };

    latitude = mkOption {
      type = types.nullOr types.float;
      default = null;
      description = "Home latitude for sun-based automations";
    };

    longitude = mkOption {
      type = types.nullOr types.float;
      default = null;
      description = "Home longitude for sun-based automations";
    };
  };

  # ════════════════════════════════════════════
  # IMPLEMENTATION
  # ════════════════════════════════════════════
  config.dotfiles.nixos.hostModules.gary = mkAfter [
    (
      { config, ... }:
      let
        cfg = config.dotfiles.gary.homeAssistant;
      in
      mkIf cfg.enable {
        services.home-assistant = {
          enable = true;
          openFirewall = true;

          extraComponents = [
          # Lights
          "hue" # Philips Hue
          "yeelight" # Xiaomi Yeelight
          "wiz" # WiZ bulbs
          "tplink" # TP-Link Kasa
          "tradfri" # IKEA Tradfri

          # Zigbee/Z-Wave (if you have a coordinator)
          "zha" # Zigbee Home Automation
          "zwave_js" # Z-Wave JS

          # Music & Media
          "spotify"
          "cast" # Chromecast
          "dlna_dmr" # DLNA renderers
          "mpd" # Music Player Daemon
          "sonos"

          # Network & Discovery
          "ssdp"
          "zeroconf"
          "dhcp"

          # Useful integrations
          "mobile_app" # Home Assistant Companion app
          "esphome" # ESP-based devices
          "mqtt" # MQTT broker support
          "webhook"
          "bluetooth"

          # System monitoring
          "systemmonitor"

          # AdGuard Home integration
          "adguard"

          # Time & Date
          "sun"
          "time_date"

          # Notifications
          "html5"
        ];

        config = {
          homeassistant = {
            name = cfg.homeName;
            unit_system = "metric";
            time_zone = cfg.timezone;
            # Customize entity names and icons
            customize = {
              "light.living_room" = {
                friendly_name = "Living Room Light";
                icon = "mdi:ceiling-light";
              };
            };
          };

          # Enable default integrations
          default_config = { };

          # HTTP configuration
          http = {
            server_port = 8123;
            ip_ban_enabled = true;
            login_attempts_threshold = 5;
            # Trust nginx reverse proxy
            use_x_forwarded_for = true;
            trusted_proxies = [
              "127.0.0.1"
              "::1"
            ];
          };

          # ============================================
          # INPUT HELPERS (for UI controls)
          # ============================================
          input_boolean = {
            guest_mode = {
              name = "Guest Mode";
              icon = "mdi:account-group";
            };
            sleep_mode = {
              name = "Sleep Mode";
              icon = "mdi:sleep";
            };
            music_follows_me = {
              name = "Music Follows Me";
              icon = "mdi:music-note";
            };
          };

          input_select = {
            house_mode = {
              name = "House Mode";
              options = [
                "Home"
                "Away"
                "Night"
                "Party"
              ];
              icon = "mdi:home-variant";
            };
          };

          input_number = {
            default_brightness = {
              name = "Default Brightness";
              min = 0;
              max = 100;
              step = 5;
              unit_of_measurement = "%";
              icon = "mdi:brightness-percent";
            };
          };

          # ============================================
          # DECLARATIVE AUTOMATIONS
          # ============================================
          # Nix-defined automations
          "automation nixos" = [
            # --- Lighting Automations ---
            {
              alias = "Lights on at sunset";
              description = "Turn on lights when sun sets";
              trigger = [
                {
                  platform = "sun";
                  event = "sunset";
                  offset = "-00:30:00"; # 30 min before sunset
                }
              ];
              condition = [
                {
                  condition = "state";
                  entity_id = "input_select.house_mode";
                  state = "Home";
                }
              ];
              action = [
                {
                  service = "light.turn_on";
                  target.entity_id = "all";
                  data = {
                    brightness_pct = 70;
                    transition = 300; # 5 min fade in
                  };
                }
              ];
            }
            {
              alias = "Lights off at sunrise";
              trigger = [
                {
                  platform = "sun";
                  event = "sunrise";
                  offset = "00:30:00";
                }
              ];
              action = [
                {
                  service = "light.turn_off";
                  target.entity_id = "all";
                  data.transition = 300;
                }
              ];
            }
            {
              alias = "Night mode - dim lights";
              trigger = [
                {
                  platform = "state";
                  entity_id = "input_select.house_mode";
                  to = "Night";
                }
              ];
              action = [
                {
                  service = "light.turn_on";
                  target.entity_id = "all";
                  data = {
                    brightness_pct = 20;
                    color_temp = 500; # Warm white
                    transition = 60;
                  };
                }
                {
                  service = "input_boolean.turn_on";
                  target.entity_id = "input_boolean.sleep_mode";
                }
              ];
            }

            # --- Party Mode ---
            {
              alias = "Party mode - colorful lights";
              trigger = [
                {
                  platform = "state";
                  entity_id = "input_select.house_mode";
                  to = "Party";
                }
              ];
              action = [
                {
                  service = "light.turn_on";
                  target.entity_id = "all";
                  data = {
                    brightness_pct = 100;
                    effect = "colorloop";
                  };
                }
              ];
            }

            # --- Away Mode ---
            {
              alias = "Away mode - security lights";
              description = "Random lights when away to simulate presence";
              trigger = [
                {
                  platform = "state";
                  entity_id = "input_select.house_mode";
                  to = "Away";
                }
              ];
              action = [
                {
                  service = "light.turn_off";
                  target.entity_id = "all";
                }
              ];
            }

            # --- System Monitoring ---
            {
              alias = "Alert on high CPU usage";
              trigger = [
                {
                  platform = "numeric_state";
                  entity_id = "sensor.processor_use";
                  above = 90;
                  for = "00:05:00"; # 5 minutes
                }
              ];
              action = [
                {
                  service = "persistent_notification.create";
                  data = {
                    title = "High CPU Usage";
                    message = "CPU usage has been above 90% for 5 minutes";
                  };
                }
              ];
            }
            {
              alias = "Alert on low disk space";
              trigger = [
                {
                  platform = "numeric_state";
                  entity_id = "sensor.disk_use_percent";
                  above = 85;
                }
              ];
              action = [
                {
                  service = "persistent_notification.create";
                  data = {
                    title = "Low Disk Space";
                    message = "Disk usage is above 85%";
                  };
                }
              ];
            }

            # --- Bluetooth Audio Hub ---
            {
              alias = "Notify on Bluetooth device connected";
              trigger = [
                {
                  platform = "state";
                  entity_id = "binary_sensor.bluetooth";
                  to = "on";
                }
              ];
              action = [
                {
                  service = "persistent_notification.create";
                  data = {
                    title = "Bluetooth";
                    message = "A Bluetooth device has connected";
                  };
                }
              ];
            }
          ];

          # Allow UI-created automations alongside Nix ones
          "automation ui" = "!include automations.yaml";

          # ============================================
          # SCENES
          # ============================================
          scene = [
            {
              name = "Movie Time";
              icon = "mdi:movie-open";
              entities = {
                "light.living_room" = {
                  state = "on";
                  brightness_pct = 15;
                  color_temp = 500;
                };
              };
            }
            {
              name = "Reading";
              icon = "mdi:book-open-variant";
              entities = {
                "light.living_room" = {
                  state = "on";
                  brightness_pct = 80;
                  color_temp = 300;
                };
              };
            }
            {
              name = "Romantic";
              icon = "mdi:heart";
              entities = {
                "light.living_room" = {
                  state = "on";
                  brightness_pct = 30;
                  rgb_color = [
                    255
                    100
                    100
                  ];
                };
              };
            }
            {
              name = "All Off";
              icon = "mdi:power";
              entities = {
                "light.living_room".state = "off";
              };
            }
          ];

          # ============================================
          # SCRIPTS
          # ============================================
          script = {
            good_morning = {
              alias = "Good Morning";
              icon = "mdi:weather-sunny";
              sequence = [
                {
                  service = "input_select.select_option";
                  target.entity_id = "input_select.house_mode";
                  data.option = "Home";
                }
                {
                  service = "light.turn_on";
                  target.entity_id = "all";
                  data = {
                    brightness_pct = 100;
                    color_temp = 250; # Cool white
                    transition = 120;
                  };
                }
              ];
            };
            good_night = {
              alias = "Good Night";
              icon = "mdi:weather-night";
              sequence = [
                {
                  service = "input_select.select_option";
                  target.entity_id = "input_select.house_mode";
                  data.option = "Night";
                }
                {
                  delay = "00:00:30";
                }
                {
                  service = "light.turn_off";
                  target.entity_id = "all";
                  data.transition = 60;
                }
              ];
            };
            flash_lights = {
              alias = "Flash Lights";
              icon = "mdi:flash";
              description = "Flash lights for notifications";
              sequence = [
                {
                  repeat = {
                    count = 3;
                    sequence = [
                      {
                        service = "light.turn_off";
                        target.entity_id = "all";
                      }
                      { delay = "00:00:01"; }
                      {
                        service = "light.turn_on";
                        target.entity_id = "all";
                      }
                      { delay = "00:00:01"; }
                    ];
                  };
                }
              ];
            };
          };

          # ============================================
          # SHELL COMMANDS (for system integration)
          # ============================================
          shell_command = {
            # Bluetooth audio controls
            bluetooth_reconnect = "bluetoothctl connect {{ device_mac }}";
            bluetooth_disconnect = "bluetoothctl disconnect";

            # System commands
            restart_pipewire = "systemctl --user restart pipewire";
          };

          # ============================================
          # SENSORS (templates)
          # ============================================
          "sensor nixos" = [
            {
              platform = "systemmonitor";
              resources = [
                { type = "disk_use_percent"; arg = "/"; }
                { type = "memory_use_percent"; }
                { type = "processor_use"; }
                { type = "load_1m"; }
                { type = "last_boot"; }
              ];
            }
          ];

          template = [
            {
              sensor = [
                {
                  name = "House Status";
                  state = "{{ states('input_select.house_mode') }}";
                  icon = ''
                    {% if is_state('input_select.house_mode', 'Home') %}
                      mdi:home
                    {% elif is_state('input_select.house_mode', 'Away') %}
                      mdi:home-export-outline
                    {% elif is_state('input_select.house_mode', 'Night') %}
                      mdi:weather-night
                    {% else %}
                      mdi:party-popper
                    {% endif %}
                  '';
                }
              ];
            }
          ];

          # ============================================
          # GROUPS
          # ============================================
          group = {
            all_lights = {
              name = "All Lights";
              entities = [
                "light.living_room"
                "light.bedroom"
                "light.kitchen"
              ];
            };
          };

          # ============================================
          # LOVELACE DASHBOARD
          # ============================================
          lovelace.mode = "yaml";
        };

        # Lovelace dashboard configuration
        lovelaceConfig = {
          title = "Gary Home";
          views = [
            {
              title = "Home";
              icon = "mdi:home";
              cards = [
                {
                  type = "entities";
                  title = "House Mode";
                  entities = [
                    "input_select.house_mode"
                    "input_boolean.guest_mode"
                    "input_boolean.sleep_mode"
                  ];
                }
                {
                  type = "entities";
                  title = "Quick Actions";
                  entities = [
                    { entity = "script.good_morning"; name = "Good Morning"; }
                    { entity = "script.good_night"; name = "Good Night"; }
                  ];
                }
                {
                  type = "button";
                  name = "All Off";
                  icon = "mdi:power";
                  tap_action = {
                    action = "call-service";
                    service = "scene.turn_on";
                    service_data.entity_id = "scene.all_off";
                  };
                }
              ];
            }
            {
              title = "Lights";
              icon = "mdi:lightbulb-group";
              cards = [
                {
                  type = "light";
                  entity = "light.living_room";
                  name = "Living Room";
                }
                {
                  type = "entities";
                  title = "Scenes";
                  entities = [
                    "scene.movie_time"
                    "scene.reading"
                    "scene.romantic"
                  ];
                }
              ];
            }
            {
              title = "System";
              icon = "mdi:server";
              cards = [
                {
                  type = "gauge";
                  entity = "sensor.processor_use";
                  name = "CPU";
                  min = 0;
                  max = 100;
                  severity = {
                    green = 0;
                    yellow = 60;
                    red = 85;
                  };
                }
                {
                  type = "gauge";
                  entity = "sensor.memory_use_percent";
                  name = "Memory";
                  min = 0;
                  max = 100;
                  severity = {
                    green = 0;
                    yellow = 60;
                    red = 85;
                  };
                }
                {
                  type = "gauge";
                  entity = "sensor.disk_use_percent";
                  name = "Disk";
                  min = 0;
                  max = 100;
                  severity = {
                    green = 0;
                    yellow = 70;
                    red = 85;
                  };
                }
              ];
            }
          ];
        };
      };

      # Recommended: enable avahi for device discovery
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };

        # For Bluetooth support
        hardware.bluetooth.enable = lib.mkDefault true;
      }
    )
  ];
}
