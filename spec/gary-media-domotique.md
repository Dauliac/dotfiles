# Gary: media stack + domotique — Specification

Status: proposed
Owner: dauliac
Related beads: dotfiles-w60, dotfiles-5xj, dotfiles-0sd (superseded by
this spec's decomposition — see plan)

## User-visible outcome

Gary (the home-server NixOS host at `10.10.0.12`) provides:

### A) A "request → download → play" media pipeline

From any device on the LAN, a user can:

1. Browse **Jellyfin** at `jellyfin.gary.local` — see the library,
   play movies and series, cast to any Chromecast/AirPlay/DLNA target
   already discovered by the host.
2. Request a new title from **Jellyseerr** at `jellyseerr.gary.local`.
   The request lands in Sonarr (series) or Radarr (movies) and the
   correct indexer (Prowlarr) picks a release.
3. The download client (**qBittorrent**) fetches the release inside a
   **WireGuard network namespace** so the host IP is never exposed to
   trackers. If the VPN drops, downloads stop — no leak.
4. **Bazarr** auto-fetches subtitles in the languages the user
   declared (French, English).
5. **Recyclarr** keeps Sonarr/Radarr quality profiles and custom
   formats aligned with TRaSH-guides recommendations.
6. **Prowlarr** is the only place where indexer credentials live —
   Sonarr/Radarr/Lidarr/Bazarr pull config from Prowlarr, not from
   individual configs.

All arr services share a **PostgreSQL** backend for durability.

### B) A domotique hub

From any device on the LAN, a user can:

1. Open **Home Assistant** at `hass.gary.local` — see the dashboard.
2. Control lights (Hue, Yeelight, WiZ, TP-Link, IKEA Tradfri) and
   media (Sonos, Chromecast, MPD, Spotify).
3. See the current state of the media stack directly on the HA
   dashboard: Sonarr queue count, Radarr queue count, active qBit
   downloads, Jellyfin now-playing, storage % used.
4. Search TMDB and add a title to the request queue **from inside
   Home Assistant** (via the Hassarr custom component).
5. Talk to the local **MQTT broker** (`mqtt.gary.local:1883`) for
   ESPHome devices and third-party integrations.
6. Manage Zigbee devices through **Zigbee2MQTT** at
   `zigbee2mqtt.gary.local` (assumes a USB Zigbee coordinator is
   plugged in — Sonoff ZBDongle-E or similar).
7. Manage ESP devices through **ESPHome** at `esphome.gary.local`.
8. Commission Matter devices through a local **matter-server**.
9. Rely on declarative automations (already defined): sunset lights,
   night mode, party mode, away mode, CPU/disk alerts, Bluetooth
   notification. New automations from this spec:
   - Movie Time scene now dims **and** starts Jellyfin on the living-room
     Chromecast, subject to `input_boolean.movie_mode`.
   - Alert on Sonarr/Radarr download failure via HA persistent
     notification.

## Non-goals

- **No Plex.** Jellyfin only.
- **No Overseerr.** Jellyseerr (fork) only.
- **No hand-managed indexer configs** — Prowlarr sync only.
- **No public exposure yet.** `featureFlags.acme = true` stays on
  (for HTTPS on the LAN via DNS-01) but no ports are opened past the
  router. Public exposure is defined in
  [gary-public-exposure.md](gary-public-exposure.md) — layered on top of
  this spec, deployed after Stages A–C are green.
- **No Frigate, no HomeKit, no Node-RED, no InfluxDB** in this pass —
  scope creep; separate specs when needed.
- **No live migration of existing HA state.** The declarative config
  replaces the mutable one; UI-created automations survive via
  `!include automations.yaml`.

## Constraints (from constitution)

- Every new service ships **behind a feature flag** in
  `systemConstants.gary.featureFlags` and is routed through the
  existing reverse proxy.
- Secrets (`jellyfin-admin-password`, arr API keys, WireGuard config,
  MQTT broker password) live in SOPS.
- No mutation outside Nix — Jellyfin admin user is created
  declaratively, HA integrations are added via `extraComponents`, etc.
- New subdomains (`mqtt`, `zigbee2mqtt`, `esphome`) auto-appear on the
  landing page at `gary.local`.

## Acceptance criteria

Feature is done when, on a freshly-deployed gary:

1. `curl -sf https://jellyfin.gary.local/health` returns 200.
2. `curl -sf https://sonarr.gary.local/api/v3/system/status -H "X-Api-Key: $(sops -d …)"` returns healthy.
3. `systemctl status nixflix-*` shows all arr units active.
4. Jellyseerr auto-connects to Sonarr + Radarr on first boot (via the
   nixflix setup service).
5. qBittorrent is confined to the `wg` netns:
   `ip netns exec wg curl ifconfig.me` returns the VPN egress IP,
   `curl ifconfig.me` returns the ISP IP.
6. Home Assistant loads without errors:
   `journalctl -u home-assistant | grep -i error` is empty for the
   last boot.
7. Mosquitto accepts a `mosquitto_pub -h localhost -t test -m hi`
   from a LAN client with the SOPS-provisioned password.
8. `hass.gary.local` shows the Media dashboard with Sonarr, Radarr,
   qBit, Jellyfin cards populated (values may be zero but sensors
   must exist).
9. `nix flake check` and `nix build .#nixosConfigurations.gary.config.system.build.toplevel` succeed.
10. `xi rollback` returns gary to the previous generation cleanly.

## Out-of-band prerequisites (user-provided)

Before deployment, `dauliac` must place these into SOPS:

- `mqtt-broker-password` — mosquitto broker password
- `zigbee2mqtt-frontend-token` — zigbee2mqtt web token (optional)
- `wireguard-mullvad-conf` — full wg-quick config file (Mullvad / AirVPN / ProtonVPN)
- `hassarr-tmdb-api-key` — TMDB v3 API key (free from themoviedb.org)

And plug in a Zigbee coordinator (Sonoff ZBDongle-E recommended)
before enabling `featureFlags.zigbee2mqtt`.
