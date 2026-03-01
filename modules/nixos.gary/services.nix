# Service definitions for reverse proxy
# Shared between acme.nix and reverse-proxy.nix
{ lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types;

  # Service type definition
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
  # ════════════════════════════════════════════
  # OPTIONS
  # ════════════════════════════════════════════
  options.dotfiles.gary.services = mkOption {
    type = types.attrsOf serviceType;
    default = { };
    description = "Services to expose via reverse proxy";
  };

  # ════════════════════════════════════════════
  # DEFAULT VALUES
  # ════════════════════════════════════════════
  config.dotfiles.gary.services = {
    hass = {
      enable = lib.mkDefault true;
      port = 8123;
      subdomain = "hass";
      description = "Home Assistant";
      extraNginxConfig = ''
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
      '';
    };
    adguard = {
      enable = lib.mkDefault true;
      port = 3000;
      subdomain = "adguard";
      description = "AdGuard Home DNS";
    };
    jellyfin = {
      enable = lib.mkDefault true;
      port = 8096;
      subdomain = "jellyfin";
      description = "Jellyfin Media Server";
      extraNginxConfig = "proxy_buffering off;";
    };
    jellyseerr = {
      enable = lib.mkDefault true;
      port = 5055;
      subdomain = "jellyseerr";
      description = "Jellyseerr Requests";
    };
    sonarr = {
      enable = lib.mkDefault true;
      port = 8989;
      subdomain = "sonarr";
      description = "Sonarr TV Shows";
    };
    radarr = {
      enable = lib.mkDefault true;
      port = 7878;
      subdomain = "radarr";
      description = "Radarr Movies";
    };
    lidarr = {
      enable = lib.mkDefault true;
      port = 8686;
      subdomain = "lidarr";
      description = "Lidarr Music";
    };
    prowlarr = {
      enable = lib.mkDefault true;
      port = 9696;
      subdomain = "prowlarr";
      description = "Prowlarr Indexers";
    };
  };
}
