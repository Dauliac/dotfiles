# HTTP reverse proxy (non-TLS) for local network
# Only active when acme.enable = false
# Uses services defined in services.nix
{ lib, ... }:
let
  inherit (lib) mkIf mkAfter filterAttrs mapAttrsToList foldl' attrNames concatStringsSep;
in
{
  config.dotfiles.nixos.hostModules.gary = mkAfter [
    (
      { config, ... }:
      let
        cfg = config.dotfiles.gary;
        domain = cfg.domain.local;
        enabledServices = filterAttrs (_: svc: svc.enable) cfg.services;

        mkVirtualHost = name: svc: {
          "${svc.subdomain}.${domain}" = {
            forceSSL = false;
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString svc.port}";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
              '' + svc.extraNginxConfig;
            };
          };
        };

        virtualHosts = foldl' (acc: name: acc // mkVirtualHost name enabledServices.${name}) { } (attrNames enabledServices);

        dnsRewrites = mapAttrsToList (name: svc: {
          domain = "${svc.subdomain}.${domain}";
          answer = cfg.network.lanIP;
        }) enabledServices;
      in
      # Only enable when ACME is disabled
      mkIf (!cfg.acme.enable) {
        services.nginx = {
          enable = true;
          recommendedProxySettings = true;
          recommendedOptimisation = true;
          recommendedGzipSettings = true;

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
                    a { display: block; padding: 20px; background: #16213e; border-radius: 8px; color: #00d4ff; text-decoration: none; }
                    a:hover { transform: translateY(-3px); background: #1a2744; }
                    .desc { color: #888; font-size: 0.9em; margin-top: 5px; }
                  </style>
                </head>
                <body>
                  <h1>🏠 Gary Services</h1>
                  <div class="services">
                    ${concatStringsSep "\n" (mapAttrsToList (name: svc:
                      "<a href=\"http://${svc.subdomain}.${domain}\"><strong>${svc.description}</strong><div class=\"desc\">${svc.subdomain}.${domain}</div></a>"
                    ) enabledServices)}
                  </div>
                </body>
                </html>'
              '';
              extraConfig = "default_type text/html;";
            };
          };

          inherit virtualHosts;
        };

        # Local DNS rewrites
        services.adguardhome.settings.filtering.rewrites = mkIf cfg.adguard.enable (
          dnsRewrites ++ [
            { domain = domain; answer = cfg.network.lanIP; }
            { domain = "*.${domain}"; answer = cfg.network.lanIP; }
          ]
        );

        networking.firewall.allowedTCPPorts = [ 80 ];
      }
    )
  ];
}
