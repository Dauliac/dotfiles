{
  flake.modules.nixos.gary-acme =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) filterAttrs mapAttrsToList foldl' attrNames concatStringsSep mkIf;
      gary = config.systemConstants.gary;
      domain = gary.domain.public;
      enabledServices = filterAttrs (_: svc: svc.enable) gary.services;

      mkVirtualHost = _: svc: {
        "${svc.subdomain}.${domain}" = {
          forceSSL = true;
          useACMEHost = domain;
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

      serviceVirtualHosts = foldl' (acc: name: acc // mkVirtualHost name enabledServices.${name}) { } (attrNames enabledServices);

      landingPageVirtualHost = {
        "${domain}" = {
          forceSSL = true;
          useACMEHost = domain;
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
                  .lock { color: #4ade80; }
                </style>
              </head>
              <body>
                <h1>Gary Services</h1>
                <div class="services">
                  ${concatStringsSep "\n" (mapAttrsToList (_: svc:
                    "<a href=\"https://${svc.subdomain}.${domain}\"><strong>${svc.description}</strong><div class=\"desc\">${svc.subdomain}.${domain}</div></a>"
                  ) enabledServices)}
                </div>
              </body>
              </html>'
            '';
            extraConfig = "default_type text/html;";
          };
        };
      };

      virtualHosts = serviceVirtualHosts // landingPageVirtualHost;

      dnsRewrites = mapAttrsToList (_: svc: {
        domain = "${svc.subdomain}.${domain}";
        answer = gary.network.lanIP;
      }) enabledServices;
    in
    lib.mkIf gary.featureFlags.acme {
      security.acme = {
        acceptTerms = true;
        defaults.email = gary.acme.email;

        certs."${domain}" = {
          domain = "*.${domain}";
          extraDomainNames = [ domain ];
          dnsProvider = gary.acme.dnsProvider;
          environmentFile = config.sops.secrets.${gary.acme.credentialsSecret}.path;
          server = mkIf gary.acme.useStaging "https://acme-staging-v02.api.letsencrypt.org/directory";
        };
      };

      users.users.nginx.extraGroups = [ "acme" ];

      services.nginx = {
        enable = true;
        recommendedTlsSettings = true;
        recommendedProxySettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;
        inherit virtualHosts;
      };

      services.adguardhome.settings.filtering.rewrites = mkIf gary.featureFlags.adguard (
        dnsRewrites ++ [
          { domain = domain; answer = gary.network.lanIP; }
          { domain = "*.${domain}"; answer = gary.network.lanIP; }
        ]
      );

      networking.firewall.allowedTCPPorts = [ 80 443 ];

      sops.secrets.${gary.acme.credentialsSecret} = {
        owner = "acme";
        group = "acme";
      };
    };
}
