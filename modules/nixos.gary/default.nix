# NixOS configuration for host: gary
#
# This file sets values for all gary options.
# Options are defined in their respective modules:
#   - options.nix      → network, domain, media (shared)
#   - services.nix     → service definitions for reverse proxy
#   - adguard.nix      → dotfiles.gary.adguard.*
#   - acme.nix         → dotfiles.gary.acme.*
#   - bluetooth-hub.nix → dotfiles.gary.bluetooth.*
#   - home-assistant.nix → dotfiles.gary.homeAssistant.*
{ lib, ... }:
{
  # ════════════════════════════════════════════
  # CONFIGURATION VALUES
  # ════════════════════════════════════════════
  config.dotfiles.gary = {
    # Network (from options.nix)
    network = {
      lanIP = "192.168.1.100"; # ← Change to gary's actual IP
      interface = "wlp0s20f3"; # ← Change to actual interface (ip link)
      gateway = "192.168.1.1";
    };

    # Domains (from options.nix)
    domain = {
      public = "j4rd1.cloud";
      local = "gary.local";
    };

    # Media directories (from options.nix)
    media = {
      dataDir = "/data/media";
      stateDir = "/data/.state";
    };

    # ACME/TLS (from acme.nix)
    acme = {
      enable = true; # Set false for HTTP-only local network
      email = "admin@j4rd1.cloud";
      dnsProvider = "cloudflare"; # Your DNS provider
      useStaging = false; # Set true for testing
    };

    # Home Assistant (from home-assistant.nix)
    homeAssistant = {
      enable = true;
      timezone = "Europe/Paris";
      homeName = "Home";
    };

    # AdGuard DNS (from adguard.nix)
    adguard = {
      enable = true;
    };

    # Bluetooth audio hub (from bluetooth-hub.nix)
    bluetooth = {
      enable = true;
      deviceName = "Gary Audio Hub";
    };

    # Services for reverse proxy (from services.nix)
    # Defaults are already set, override here if needed:
    # services.lidarr.enable = false;
  };

  # ════════════════════════════════════════════
  # HOST CONFIGURATION
  # ════════════════════════════════════════════
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (_: {
      networking.hostName = "gary";
    })
  ];
}
