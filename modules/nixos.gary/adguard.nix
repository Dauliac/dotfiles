{
  flake.modules.nixos.gary-adguard =
    {
      config,
      lib,
      ...
    }:
    let
      gary = config.systemConstants.gary;
      adguard = gary.adguard;
    in
    lib.mkIf gary.featureFlags.adguard {
      services.adguardhome = {
        enable = true;
        openFirewall = true;
        port = adguard.port;

        settings = {
          dns = {
            bind_hosts = [ "0.0.0.0" ];
            port = adguard.dnsPort;
            upstream_dns = adguard.upstreamDNS;
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

          filters = lib.imap0 (i: filter: {
            enabled = filter.enabled;
            url = filter.url;
            name = filter.name;
            id = i + 1;
          }) adguard.blocklists;

          http.address = "0.0.0.0:${toString adguard.port}";

          statistics = {
            enabled = true;
            interval = "24h";
          };
        };
      };

      networking.firewall = {
        allowedTCPPorts = [ adguard.dnsPort ];
        allowedUDPPorts = [ adguard.dnsPort ];
      };

      networking.nameservers = lib.mkDefault [ "127.0.0.1" ];
    };
}
