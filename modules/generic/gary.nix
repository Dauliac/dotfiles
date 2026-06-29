_: {
  flake.modules.generic.gary-constants =
    { lib, ... }:
    {
      options.systemConstants.gary = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified;
        default = { };
        description = "Gary host constants (domain, network, media, services, ...)";
      };

      config.systemConstants.gary = {
        network = {
          lanIP = "10.10.0.12";
          interface = "wlp0s20f3";
          gateway = "10.10.0.1";
        };

        domain = {
          public = "j4rd1.cloud";
          local = "gary.local";
        };

        media = {
          dataDir = "/data/media";
          stateDir = "/data/.state";
        };

        acme = {
          email = "admin@j4rd1.cloud";
          dnsProvider = "cloudflare";
          credentialsSecret = "acme-dns-credentials";
          useStaging = false;
        };

        homeAssistant = {
          timezone = "Europe/Paris";
          homeName = "Home";
          latitude = null;
          longitude = null;
        };

        bluetooth = {
          deviceName = "Gary 🐌";
          alwaysDiscoverable = true;
          codecs = [
            "sbc"
            "sbc_xq"
            "aac"
            "ldac"
            "aptx"
            "aptx_hd"
            "aptx_ll"
            "aptx_ll_duplex"
          ];
        };

        airplay = {
          deviceName = "Gary 🐌";
          screenMirroring = {
            resolution = "1920x1080";
            fps = 60;
            lowLatency = true;
            fullscreen = true;
          };
          audio = {
            airplay2 = true;
            volumeRangeDb = 60;
          };
        };

        adguard = {
          port = 3000;
          dnsPort = 53;
          upstreamDNS = [
            "https://dns.cloudflare.com/dns-query"
            "https://dns.google/dns-query"
            "1.1.1.1"
            "8.8.8.8"
          ];
          blocklists = [
            {
              name = "AdGuard DNS filter";
              url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
              enabled = true;
            }
            {
              name = "AdAway Default Blocklist";
              url = "https://adaway.org/hosts.txt";
              enabled = true;
            }
            {
              name = "Steven Black's Unified Hosts";
              url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
              enabled = true;
            }
            {
              name = "OISD Blocklist Basic";
              url = "https://basic.oisd.nl/";
              enabled = true;
            }
            {
              name = "Phishing Army";
              url = "https://phishing.army/download/phishing_army_blocklist_extended.txt";
              enabled = true;
            }
            {
              name = "NoCoin Filter List";
              url = "https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt";
              enabled = true;
            }
            {
              name = "EasyPrivacy";
              url = "https://v.firebog.net/hosts/Easyprivacy.txt";
              enabled = true;
            }
            {
              name = "Prigent Ads";
              url = "https://v.firebog.net/hosts/Prigent-Ads.txt";
              enabled = true;
            }
          ];
        };

        # Feature flags: decide which gary-* aspects get imported by host-gary.
        # These live in one place per the Constants Aspect pattern.
        featureFlags = {
          acme = true;
          adguard = true;
          bluetoothHub = true;
          homeAssistant = true;
          airplay = true;
          airplayScreenMirroring = true;
          airplayAudio = true;
          reverseProxy = false; # active only when ACME is off (set by VM variant)
          nixflix = false; # upstream option churn (jellyfin.apiKey, seerr); re-enable once nixflix input stabilizes
        };

        # Services exposed through the reverse proxy.
        services = {
          hass = {
            enable = true;
            port = 8123;
            subdomain = "hass";
            description = "Home Assistant";
            extraNginxConfig = ''
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            '';
          };
          adguard = {
            enable = true;
            port = 3000;
            subdomain = "adguard";
            description = "AdGuard Home DNS";
            extraNginxConfig = "";
          };
          jellyfin = {
            enable = true;
            port = 8096;
            subdomain = "jellyfin";
            description = "Jellyfin Media Server";
            extraNginxConfig = "proxy_buffering off;";
          };
          jellyseerr = {
            enable = true;
            port = 5055;
            subdomain = "jellyseerr";
            description = "Jellyseerr Requests";
            extraNginxConfig = "";
          };
          sonarr = {
            enable = true;
            port = 8989;
            subdomain = "sonarr";
            description = "Sonarr TV Shows";
            extraNginxConfig = "";
          };
          radarr = {
            enable = true;
            port = 7878;
            subdomain = "radarr";
            description = "Radarr Movies";
            extraNginxConfig = "";
          };
          lidarr = {
            enable = true;
            port = 8686;
            subdomain = "lidarr";
            description = "Lidarr Music";
            extraNginxConfig = "";
          };
          prowlarr = {
            enable = true;
            port = 9696;
            subdomain = "prowlarr";
            description = "Prowlarr Indexers";
            extraNginxConfig = "";
          };
        };
      };
    };
}
