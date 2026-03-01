# Centralized reverse proxy for all services
# Uses nginx with local DNS via AdGuard Home
# Configuration comes from dotfiles.gary options
{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (
      { config, ... }:
      let
        cfg = config.dotfiles.gary;
        domain = cfg.domain.local;
        enabledServices = lib.filterAttrs (_: svc: svc.enable) cfg.services;

        # Generate nginx virtual host for a service
        mkVirtualHost = name: svc: {
          "${svc.subdomain}.${domain}" = {
            forceSSL = false;
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString svc.port}";
              proxyWebsockets = true;
              extraConfig =
                ''
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
                ''
                + svc.extraNginxConfig;
            };
          };
        };

        virtualHosts = lib.foldl' (acc: name: acc // mkVirtualHost name enabledServices.${name}) { } (
          lib.attrNames enabledServices
        );

        # Generate DNS rewrites for AdGuard Home
        dnsRewrites = lib.mapAttrsToList (name: svc: {
          domain = "${svc.subdomain}.${domain}";
          answer = cfg.network.lanIP;
        }) enabledServices;
      in
      {
        # Only enable if ACME is disabled (use acme.nix for TLS)
        services.nginx = lib.mkIf (!cfg.acme.enable) {
          enable = true;
          recommendedProxySettings = true;
          recommendedOptimisation = true;
          recommendedGzipSettings = true;

          # Landing page
          virtualHosts."${domain}" = {
            default = true;
            locations."/" = {
              return = ''
                200 '<!DOCTYPE html>
                <html>
                <head>
                  <title>Gary Services</title>
                  <style>
                    body { font-family: system-ui; max-width: 800px; margin: 50px auto; padding: 20px; background: #1a1a2e; color: #eee; }
                    h1 { color: #00d4ff; }
                    .services { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 15px; }
                    a { display: block; padding: 20px; background: #16213e; border-radius: 8px; color: #00d4ff; text-decoration: none; transition: transform 0.2s; }
                    a:hover { transform: translateY(-3px); background: #1a2744; }
                    .desc { color: #888; font-size: 0.9em; margin-top: 5px; }
                  </style>
                </head>
                <body>
                  <h1>🏠 Gary Services</h1>
                  <div class="services">
                    ${lib.concatStringsSep "\n" (
                      lib.mapAttrsToList (
                        name: svc:
                        "<a href=\"http://${svc.subdomain}.${domain}\"><strong>${svc.description}</strong><div class=\"desc\">${svc.subdomain}.${domain}</div></a>"
                      ) enabledServices
                    )}
                  </div>
                </body>
                </html>'
              '';
              extraConfig = "default_type text/html;";
            };
          };

          inherit virtualHosts;
        };

        # AdGuard DNS rewrites for local domain resolution
        services.adguardhome.settings.filtering.rewrites = lib.mkIf cfg.adguard.enable (
          dnsRewrites
          ++ [
            {
              domain = domain;
              answer = cfg.network.lanIP;
            }
            {
              domain = "*.${domain}";
              answer = cfg.network.lanIP;
            }
          ]
        );

        networking.firewall.allowedTCPPorts = lib.mkIf (!cfg.acme.enable) [ 80 ];
      }
    )
  ];
}
