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

      # Cloudflare API token (bare value in secrets.yaml). Consumed only via
      # the cloudflare-acme.env template below - lego wants CF_DNS_API_TOKEN=
      # as an environment file, not a raw string.
      sops.secrets.gary_cloudflare_token = lib.mkIf gary.featureFlags.acme { };

      # Dashboard-managed Cloudflare Tunnel connect token (bare value).
      # Consumed only via the cloudflared-tunnel.env template below.
      sops.secrets.gary_cloudflared_tunnel_token = lib.mkIf gary.featureFlags.cloudflared { };

      # Rendered env files - sops-nix writes KEY=VALUE lines that systemd's
      # EnvironmentFile= can source. Raw tokens stay unprefixed in secrets.yaml
      # so they remain reusable from other tooling.
      sops.templates."cloudflare-acme.env" = lib.mkIf gary.featureFlags.acme {
        owner = "acme";
        group = "acme";
        mode = "0400";
        content = ''
          CF_DNS_API_TOKEN=${config.sops.placeholder.gary_cloudflare_token}
        '';
      };

      sops.templates."cloudflared-tunnel.env" = lib.mkIf gary.featureFlags.cloudflared {
        mode = "0400";
        content = ''
          TUNNEL_TOKEN=${config.sops.placeholder.gary_cloudflared_tunnel_token}
        '';
      };
    };
}
