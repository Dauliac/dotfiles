# NixOS configuration for host: gary
# Auto-imported by import-tree - no imports needed
#
# This file sets the high-level options for gary.
# All services read from config.dotfiles.gary.*
{ lib, ... }:
{
  # Gary-specific options (defined in modules/options/gary.nix)
  config.dotfiles.gary = {
    # Network
    network = {
      lanIP = "192.168.1.100"; # Change to gary's actual IP
      interface = "wlp0s20f3"; # Change to actual interface (ip link)
      gateway = "192.168.1.1";
    };

    # Domains
    domain = {
      public = "j4rd1.cloud";
      local = "gary.local";
    };

    # ACME / TLS certificates
    acme = {
      enable = true; # Set to false for HTTP-only (local network)
      email = "admin@j4rd1.cloud";
      dnsProvider = "cloudflare"; # Change to your provider
      useStaging = false; # Set true for testing
    };

    # Enable features
    homeAssistant = {
      enable = true;
      timezone = "Europe/Paris";
      homeName = "Home";
    };

    adguard = {
      enable = true;
      upstreamDNS = [
        "https://dns.cloudflare.com/dns-query"
        "https://dns.google/dns-query"
        "1.1.1.1"
        "8.8.8.8"
      ];
    };

    bluetooth = {
      enable = true;
      deviceName = "Gary Audio Hub";
    };

    # Media directories
    media = {
      dataDir = "/data/media";
      stateDir = "/data/.state";
    };

    # Services (defaults are set in options/gary.nix)
    # Override individual services here if needed:
    # services.jellyfin.enable = false;
  };

  # Basic host configuration
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (_: {
      networking.hostName = "gary";
    })
  ];
}
