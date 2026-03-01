# High-level options for gary host configuration
# Centralizes all configurable values in one place
{ lib, ... }:
let
  inherit (lib) mkOption types mkEnableOption;

  # Service definition type
  serviceType = types.submodule {
    options = {
      enable = mkEnableOption "this service";
      port = mkOption {
        type = types.port;
        description = "Port the service listens on";
      };
      subdomain = mkOption {
        type = types.str;
        description = "Subdomain for this service";
      };
      description = mkOption {
        type = types.str;
        default = "";
        description = "Human-readable description";
      };
      extraNginxConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra nginx location config";
      };
    };
  };
in
{
  options.dotfiles.gary = {
    # Network configuration
    network = {
      lanIP = mkOption {
        type = types.str;
        default = "192.168.1.100";
        description = "Gary's LAN IP address";
        example = "192.168.1.100";
      };

      interface = mkOption {
        type = types.str;
        default = "eth0";
        description = "Primary network interface";
      };

      gateway = mkOption {
        type = types.str;
        default = "192.168.1.1";
        description = "Default gateway / router IP";
      };
    };

    # Domain configuration
    domain = {
      public = mkOption {
        type = types.str;
        default = "j4rd1.cloud";
        description = "Public domain name";
      };

      local = mkOption {
        type = types.str;
        default = "gary.local";
        description = "Local domain name for LAN access";
      };
    };

    # ACME / TLS configuration
    acme = {
      enable = mkEnableOption "ACME certificates";

      email = mkOption {
        type = types.str;
        default = "admin@j4rd1.cloud";
        description = "Email for Let's Encrypt notifications";
      };

      dnsProvider = mkOption {
        type = types.str;
        default = "cloudflare";
        description = "DNS provider for DNS-01 challenge (cloudflare, ovh, gandi, route53, etc.)";
      };

      credentialsSecret = mkOption {
        type = types.str;
        default = "acme-dns-credentials";
        description = "Sops secret name containing DNS provider credentials";
      };

      useStaging = mkOption {
        type = types.bool;
        default = false;
        description = "Use Let's Encrypt staging server (for testing)";
      };
    };

    # Service definitions
    services = mkOption {
      type = types.attrsOf serviceType;
      default = { };
      description = "Services to expose via reverse proxy";
    };

    # Bluetooth audio hub
    bluetooth = {
      enable = mkEnableOption "Bluetooth audio hub";

      deviceName = mkOption {
        type = types.str;
        default = "Gary Audio Hub";
        description = "Bluetooth device name shown to other devices";
      };
    };

    # Home Assistant
    homeAssistant = {
      enable = mkEnableOption "Home Assistant";

      timezone = mkOption {
        type = types.str;
        default = "Europe/Paris";
        description = "Timezone for Home Assistant";
      };

      homeName = mkOption {
        type = types.str;
        default = "Home";
        description = "Name of your home in Home Assistant";
      };
    };

    # AdGuard Home
    adguard = {
      enable = mkEnableOption "AdGuard Home DNS";

      upstreamDNS = mkOption {
        type = types.listOf types.str;
        default = [
          "https://dns.cloudflare.com/dns-query"
          "https://dns.google/dns-query"
          "1.1.1.1"
          "8.8.8.8"
        ];
        description = "Upstream DNS servers";
      };
    };

    # Media directories (for nixflix)
    media = {
      dataDir = mkOption {
        type = types.path;
        default = "/data/media";
        description = "Media storage directory";
      };

      stateDir = mkOption {
        type = types.path;
        default = "/data/.state";
        description = "State/config storage directory";
      };
    };
  };

  # Default service definitions
  config.dotfiles.gary.services = {
    hass = {
      enable = true;
      port = 8123;
      subdomain = "hass";
      description = "Home Assistant";
      extraNginxConfig = ''
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
      '';
    };
    adguard = {
      enable = true;
      port = 3000;
      subdomain = "adguard";
      description = "AdGuard Home DNS";
    };
    jellyfin = {
      enable = true;
      port = 8096;
      subdomain = "jellyfin";
      description = "Jellyfin Media Server";
      extraNginxConfig = "proxy_buffering off;";
    };
    jellyseerr = {
      enable = true;
      port = 5055;
      subdomain = "jellyseerr";
      description = "Jellyseerr Requests";
    };
    sonarr = {
      enable = true;
      port = 8989;
      subdomain = "sonarr";
      description = "Sonarr TV Shows";
    };
    radarr = {
      enable = true;
      port = 7878;
      subdomain = "radarr";
      description = "Radarr Movies";
    };
    lidarr = {
      enable = true;
      port = 8686;
      subdomain = "lidarr";
      description = "Lidarr Music";
    };
    prowlarr = {
      enable = true;
      port = 9696;
      subdomain = "prowlarr";
      description = "Prowlarr Indexers";
    };
  };
}
