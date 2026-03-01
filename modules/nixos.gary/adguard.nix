# AdGuard Home DNS ad-blocking service
# Configuration comes from dotfiles.gary options
{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (
      { config, ... }:
      let
        cfg = config.dotfiles.gary;
      in
      lib.mkIf cfg.adguard.enable {
        services.adguardhome = {
          enable = true;
          openFirewall = true;
          port = 3000;

          settings = {
            dns = {
              bind_hosts = [ "0.0.0.0" ];
              port = 53;
              upstream_dns = cfg.adguard.upstreamDNS;
              bootstrap_dns = [
                "1.1.1.1"
                "8.8.8.8"
              ];
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
              # rewrites are added by reverse-proxy.nix or acme.nix
            };

            http.address = "0.0.0.0:3000";

            statistics = {
              enabled = true;
              interval = "24h";
            };
          };
        };

        networking.firewall = {
          allowedTCPPorts = [ 53 ];
          allowedUDPPorts = [ 53 ];
        };

        # Use local DNS for this machine
        networking.nameservers = lib.mkDefault [ "127.0.0.1" ];
      }
    )
  ];
}
