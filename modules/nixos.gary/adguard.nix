# AdGuard Home DNS ad-blocking service
# Defines options AND implementation together
{ lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types mkIf mkAfter;
in
{
  # ════════════════════════════════════════════
  # OPTIONS
  # ════════════════════════════════════════════
  options.dotfiles.gary.adguard = {
    enable = mkEnableOption "AdGuard Home DNS";

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Web UI port";
    };

    dnsPort = mkOption {
      type = types.port;
      default = 53;
      description = "DNS port";
    };

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

  # ════════════════════════════════════════════
  # IMPLEMENTATION
  # ════════════════════════════════════════════
  config.dotfiles.nixos.hostModules.gary = mkAfter [
    (
      { config, ... }:
      let
        cfg = config.dotfiles.gary.adguard;
      in
      mkIf cfg.enable {
        services.adguardhome = {
          enable = true;
          openFirewall = true;
          port = cfg.port;

          settings = {
            dns = {
              bind_hosts = [ "0.0.0.0" ];
              port = cfg.dnsPort;
              upstream_dns = cfg.upstreamDNS;
              bootstrap_dns = [ "1.1.1.1" "8.8.8.8" ];
              upstream_mode = "parallel";
              cache_size = 4194304;
              cache_ttl_min = 300;
              cache_ttl_max = 86400;
            };

            filtering = {
              protection_enabled = true;
              filtering_enabled = true;
              safe_search.enabled = false;
              parental.enabled = false;
            };

            http.address = "0.0.0.0:${toString cfg.port}";

            statistics = {
              enabled = true;
              interval = "24h";
            };
          };
        };

        networking.firewall = {
          allowedTCPPorts = [ cfg.dnsPort ];
          allowedUDPPorts = [ cfg.dnsPort ];
        };

        networking.nameservers = lib.mkDefault [ "127.0.0.1" ];
      }
    )
  ];
}
