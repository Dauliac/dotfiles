{ inputs, ... }: {
  flake.modules.nixos.host-gary = { ... }: {
    imports =
      with inputs.self.modules.nixos;
      [
        base
        bluetooth
        boot
        comin
        desktop
        hardening
        locales
        niri
        xi
        secrets
        sound
        theme
        users

        gary-boot
        gary-gaming
        gary-gnome
        gary-hardware
        gary-home-manager
        gary-nixflix
        gary-osk
        gary-secrets
        gary-sleep
        gary-ssh
        gary-users

        gary-acme
        gary-adguard
        gary-bluetooth-hub
        gary-cloudflared
        gary-home-assistant
        gary-mosquitto
        gary-esphome
        gary-zigbee2mqtt
        gary-matter-server
        gary-airplay
        gary-airplay-uxplay
        gary-airplay-shairport
        gary-reverse-proxy

        # Per-service backend wiring (modules/nixos.gary/services/<name>.nix).
        # Only arrs that need a NixOS-level backend hook (nixflix.<module>
        # api-key secret) have a `flake.modules.nixos.gary-service-*`;
        # catalog-only services (hass, adguard, bazarr, qbittorrent,
        # zigbee2mqtt, esphome) live purely in the `generic` scope below.
        gary-service-jellyfin
        gary-service-jellyseerr
        gary-service-lidarr
        gary-service-prowlarr
        gary-service-radarr
        gary-service-sonarr
      ]
      ++ [
        inputs.self.modules.generic.gary-constants
        inputs.self.modules.generic.proprietary-flag
        inputs.self.modules.generic.display
        # Service catalog entries (generic scope, shared with home-manager).
        inputs.self.modules.generic.gary-service-adguard
        inputs.self.modules.generic.gary-service-bazarr
        inputs.self.modules.generic.gary-service-esphome
        inputs.self.modules.generic.gary-service-hass
        inputs.self.modules.generic.gary-service-jellyfin
        inputs.self.modules.generic.gary-service-jellyseerr
        inputs.self.modules.generic.gary-service-lidarr
        inputs.self.modules.generic.gary-service-prowlarr
        inputs.self.modules.generic.gary-service-qbittorrent
        inputs.self.modules.generic.gary-service-radarr
        inputs.self.modules.generic.gary-service-sonarr
        inputs.self.modules.generic.gary-service-zigbee2mqtt
      ];

    networking.hostName = "gary";

    # Living-room TV at viewing distance. Drives firefox devPixelsPerPx,
    # cursor size, noctalia bar sizing, and GTK/Qt scale env vars via the
    # display-constants aspect. The VM variant overrides this to 1.0 for
    # a laptop-sized sandbox.
    systemConstants.display.scale = 3.0;

    # VM-variant overrides are decomposed into gary-vm-* aspects under
    # modules/nixos.gary/vm/ - one aspect per concern so each stub lives
    # in exactly one place.
    virtualisation.vmVariant.imports = with inputs.self.modules.nixos; [
      gary-vm-arr
      gary-vm-boot
      gary-vm-display
      gary-vm-domain
      gary-vm-features
      gary-vm-hosts
      gary-vm-nix-tooling
      gary-vm-qemu
      gary-vm-secrets
      gary-vm-ssh
      gary-vm-users
    ];
  };
}
