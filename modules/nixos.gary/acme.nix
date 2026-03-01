# ACME/Let's Encrypt certificates for all services
# Uses DNS-01 challenge (works with private IPs)
# Defines options AND implementation together
{ lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types mkIf mkAfter filterAttrs mapAttrsToList foldl' attrNames concatStringsSep;
in
{
  # ════════════════════════════════════════════
  # OPTIONS
  # ════════════════════════════════════════════
  options.dotfiles.gary.acme = {
    enable = mkEnableOption "ACME/Let's Encrypt certificates";

    email = mkOption {
      type = types.str;
      default = "admin@j4rd1.cloud";
      description = "Email for Let's Encrypt notifications";
    };

    dnsProvider = mkOption {
      type = types.str;
      default = "cloudflare";
      description = "DNS provider for DNS-01 challenge";
    };

    credentialsSecret = mkOption {
      type = types.str;
      default = "acme-dns-credentials";
      description = "Sops secret name for DNS provider credentials";
    };

    useStaging = mkOption {
      type = types.bool;
      default = false;
      description = "Use Let's Encrypt staging server (for testing)";
    };
  };

  # ════════════════════════════════════════════
  # IMPLEMENTATION
  # ════════════════════════════════════════════
  config.dotfiles.nixos.hostModules.gary = mkAfter [
    (
      { config, ... }:
      let
        cfg = config.dotfiles.gary;
        acmeCfg = cfg.acme;
        domain = cfg.domain.public;
        enabledServices = filterAttrs (_: svc: svc.enable) cfg.services;

        mkVirtualHost = name: svc: {
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

        virtualHosts = foldl' (acc: name: acc // mkVirtualHost name enabledServices.${name}) { } (attrNames enabledServices);

        dnsRewrites = mapAttrsToList (name: svc: {
          domain = "${svc.subdomain}.${domain}";
          answer = cfg.network.lanIP;
        }) enabledServices;
      in
      mkIf acmeCfg.enable {
        security.acme = {
          acceptTerms = true;
          defaults.email = acmeCfg.email;

          certs."${domain}" = {
            domain = "*.${domain}";
            extraDomainNames = [ domain ];
            dnsProvider = acmeCfg.dnsProvider;
            environmentFile = config.sops.secrets.${acmeCfg.credentialsSecret}.path;
            server = mkIf acmeCfg.useStaging "https://acme-staging-v02.api.letsencrypt.org/directory";
          };
        };

        users.users.nginx.extraGroups = [ "acme" ];

        services.nginx = {
          enable = true;
          recommendedTlsSettings = true;
          recommendedProxySettings = true;
          recommendedOptimisation = true;
          recommendedGzipSettings = true;

          virtualHosts."${domain}" = {
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
                  <h1>🏠 Gary Services <span class="lock">🔒</span></h1>
                  <div class="services">
                    ${concatStringsSep "\n" (mapAttrsToList (name: svc:
                      "<a href=\"https://${svc.subdomain}.${domain}\"><strong>${svc.description}</strong><div class=\"desc\">${svc.subdomain}.${domain}</div></a>"
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

        services.adguardhome.settings.filtering.rewrites = mkIf cfg.adguard.enable (
          dnsRewrites ++ [
            { domain = domain; answer = cfg.network.lanIP; }
            { domain = "*.${domain}"; answer = cfg.network.lanIP; }
          ]
        );

        networking.firewall.allowedTCPPorts = [ 80 443 ];

        sops.secrets.${acmeCfg.credentialsSecret} = {
          sopsFile = ./secrets.yaml;
          owner = "acme";
          group = "acme";
        };
      }
    )
  ];
}
