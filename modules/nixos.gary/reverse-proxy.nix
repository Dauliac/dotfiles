# Centralized reverse proxy for all services
# Uses nginx with local DNS via AdGuard Home
{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (
      { config, ... }:
      let
        # Local domain for all services
        domain = "gary.local";

        # Service definitions: name -> { port, description }
        services = {
          # Home Automation
          hass = {
            port = 8123;
            description = "Home Assistant";
            extraConfig = ''
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            '';
          };
          adguard = {
            port = 3000;
            description = "AdGuard Home DNS";
          };

          # Media - Nixflix stack
          jellyfin = {
            port = 8096;
            description = "Jellyfin Media Server";
            extraConfig = ''
              proxy_buffering off;
            '';
          };
          jellyseerr = {
            port = 5055;
            description = "Jellyseerr Requests";
          };
          sonarr = {
            port = 8989;
            description = "Sonarr TV Shows";
          };
          radarr = {
            port = 7878;
            description = "Radarr Movies";
          };
          lidarr = {
            port = 8686;
            description = "Lidarr Music";
          };
          prowlarr = {
            port = 9696;
            description = "Prowlarr Indexers";
          };

          # Audio
          # pipewire = {
          #   port = 4713;
          #   description = "PipeWire Remote";
          # };
        };

        # Generate nginx virtual host for a service
        mkVirtualHost = name: cfg: {
          "${name}.${domain}" = {
            forceSSL = false;
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString cfg.port}";
              proxyWebsockets = true;
              extraConfig =
                ''
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
                ''
                + (cfg.extraConfig or "");
            };
          };
        };

        # Generate all virtual hosts
        virtualHosts = lib.foldl' (acc: name: acc // mkVirtualHost name services.${name}) { } (
          lib.attrNames services
        );

        # Generate DNS rewrites for AdGuard Home
        dnsRewrites = lib.mapAttrsToList (name: _: {
          domain = "${name}.${domain}";
          answer = "127.0.0.1";
        }) services;
      in
      {
        # Nginx reverse proxy
        services.nginx = {
          enable = true;
          recommendedProxySettings = true;
          recommendedOptimisation = true;
          recommendedGzipSettings = true;

          # Landing page with links to all services
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
                        name: cfg:
                        "<a href=\"http://${name}.${domain}\"><strong>${cfg.description}</strong><div class=\"desc\">${name}.${domain}</div></a>"
                      ) services
                    )}
                  </div>
                </body>
                </html>'
              '';
              extraConfig = ''
                default_type text/html;
              '';
            };
          };

          # All service virtual hosts
          virtualHosts = virtualHosts;
        };

        # AdGuard Home DNS rewrites for local domain resolution
        services.adguardhome.settings.filtering = {
          rewrites = dnsRewrites ++ [
            # Main domain
            {
              domain = domain;
              answer = "127.0.0.1";
            }
            # Wildcard for any new services
            {
              domain = "*.${domain}";
              answer = "127.0.0.1";
            }
          ];
        };

        # Open HTTP port
        networking.firewall.allowedTCPPorts = [ 80 ];

        # Ensure nginx can connect to all services
        systemd.services.nginx.wants =
          lib.mapAttrsToList (name: _: "${name}.service") services;
      }
    )
  ];
}
