{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (_: {
      services.adguardhome = {
        enable = true;
        openFirewall = true;

        # Web UI port (default 3000)
        port = 3000;

        settings = {
          # DNS settings
          dns = {
            bind_hosts = [
              "0.0.0.0"
            ];
            port = 53;

            # Upstream DNS servers
            upstream_dns = [
              "https://dns.cloudflare.com/dns-query"
              "https://dns.google/dns-query"
              "1.1.1.1"
              "8.8.8.8"
            ];

            # Bootstrap DNS (for resolving DoH hostnames)
            bootstrap_dns = [
              "1.1.1.1"
              "8.8.8.8"
            ];

            # Enable DNS-over-HTTPS
            upstream_mode = "parallel";

            # Caching
            cache_size = 4194304; # 4MB
            cache_ttl_min = 300;
            cache_ttl_max = 86400;
          };

          # Filtering settings
          filtering = {
            protection_enabled = true;
            filtering_enabled = true;

            # Block lists are configured via web UI after first start
            # These are sensible defaults
            safe_search.enabled = false;
            parental.enabled = false;
          };

          # Web UI settings
          http = {
            address = "0.0.0.0:3000";
          };

          # Statistics
          statistics = {
            enabled = true;
            interval = "24h";
          };
        };
      };

      # Open DNS port
      networking.firewall = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };

      # Use local DNS for this machine
      networking.nameservers = lib.mkDefault [ "127.0.0.1" ];
    })
  ];
}
