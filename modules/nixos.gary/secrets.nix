{
  flake.modules.nixos.gary-secrets =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (config.systemConstants) gary;
    in
    {
      sops.secrets.gary_hashed_password = {
        sopsFile = ../../secrets/passwords/gary.enc;
        format = "json";
        key = "data";
      };

      # Arr stack API keys (SOPS-managed, referenced by nixflix module).
      sops.secrets.sonarr-api-key = { };
      sops.secrets.radarr-api-key = { };
      sops.secrets.lidarr-api-key = { };
      sops.secrets.prowlarr-api-key = { };
      sops.secrets.jellyseerr-api-key = { };
      sops.secrets.jellyfin-admin-password = { };

      # MQTT broker credentials — one password per client so a compromise
      # of one integration doesn't rotate keys for the others.
      sops.secrets.mqtt-homeassistant-password = lib.mkIf gary.featureFlags.mosquitto {
        owner = "mosquitto";
        group = "mosquitto";
        mode = "0400";
      };
      sops.secrets.mqtt-zigbee2mqtt-password = lib.mkIf gary.featureFlags.mosquitto {
        owner = "mosquitto";
        group = "mosquitto";
        mode = "0400";
      };
      sops.secrets.mqtt-esphome-password = lib.mkIf gary.featureFlags.mosquitto {
        owner = "mosquitto";
        group = "mosquitto";
        mode = "0400";
      };

      # Home Assistant secrets.yaml — a rendered template that lets HA
      # resolve `!secret mqtt_password` in its declarative config.
      sops.templates."hass-secrets.yaml" = lib.mkIf gary.featureFlags.homeAssistant {
        owner = "hass";
        group = "hass";
        mode = "0400";
        path = "/var/lib/hass/secrets.yaml";
        content = ''
          mqtt_password: ${config.sops.placeholder.mqtt-homeassistant-password}
        '';
      };

      # Zigbee2MQTT frontend auth token (opt-in with the z2m flag).
      sops.secrets.zigbee2mqtt-frontend-token = lib.mkIf gary.featureFlags.zigbee2mqtt {
        owner = "zigbee2mqtt";
        group = "zigbee2mqtt";
        mode = "0400";
      };

      # WireGuard config for nixflix.vpn — a full wg-quick file with
      # [Interface] + [Peer] sections. Provided by user (Mullvad/AirVPN).
      sops.secrets.wireguard-mullvad-conf = lib.mkIf gary.featureFlags.nixflixVpn {
        mode = "0400";
      };

      # TMDB API key for the Hassarr custom component (Stage C).
      sops.secrets.hassarr-tmdb-api-key = lib.mkIf gary.featureFlags.haArrIntegration {
        owner = "hass";
        group = "hass";
        mode = "0400";
      };
    };
}
