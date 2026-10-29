_: {
  flake.modules.generic.gary-constants = { lib, ... }: {
    options.systemConstants.gary = lib.mkOption {
      type = lib.types.anything;
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
        # One domain for both LAN and internet: AdGuard owns LAN resolution
        # via `*.raylovers.club -> gary.network.lanIP` rewrites in acme.nix.
        # Public clients hit public DNS -> cloudflared tunnel edge.
        public = "raylovers.club";
        local = "raylovers.club";
      };

      media = {
        dataDir = "/data/media";
        stateDir = "/data/.state";
      };

      acme = {
        email = "admin@raylovers.club";
        dnsProvider = "cloudflare";
        # Use LE staging while iterating - unlimited rate, untrusted-cert
        # warning in browser.  Flip to false once the pipeline is proven.
        useStaging = true;
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
        cloudflared = true;
        homeAssistant = true;
        airplay = true;
        airplayScreenMirroring = true;
        airplayAudio = true;
        reverseProxy = false; # active only when ACME is off (set by VM variant)
        nixflix = true; # re-enabled: upstream option shapes at pinned rev match nixflix.nix
        nixflixVpn = false; # opt-in: needs wireguard-mullvad-conf in SOPS
        mosquitto = true; # MQTT broker for Home Assistant + ESPHome
        esphome = true; # ESPHome device dashboard
        zigbee2mqtt = false; # opt-in: needs USB Zigbee coordinator
        matterServer = false; # opt-in: Matter/Thread commissioning
        haArrIntegration = true; # HACS-packaged sensors + Media dashboard (Stage C)
        vmArrStack = false; # VM-only: standalone arr services for topology smoke tests (see modules/nixos.gary/vm/arr.nix)
      };

      # The service catalog itself lives in modules/nixos.gary/services/<name>.nix.
      # Each per-service aspect contributes its entry (port, subdomain,
      # description, extraNginxConfig, firefox bookmark metadata) AND wires
      # the backend (nixflix.<module>, services.<name>, etc.) in one place.
      # Default to the empty attrset so consumers (acme, reverse-proxy,
      # bookmarks, cloudflared, home-assistant) can iterate safely.
      services = { };

      # MQTT broker settings (mosquitto is TCP, not HTTP — sits outside the
      # reverse-proxy attrset above but referenced by home-assistant + esphome).
      mosquitto = {
        port = 1883;
        listener = "0.0.0.0"; # LAN + localhost; ufw restricts to LAN subnet
      };
    };
  };
}
