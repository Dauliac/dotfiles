# Gary: media stack + domotique — Plan

Status: proposed
Reads: [spec/gary-media-domotique.md](../spec/gary-media-domotique.md),
[memory/constitution.md](../memory/constitution.md)

## 1. Tech choices

| Concern | Choice | Alternative rejected because… |
|---|---|---|
| Media pipeline | **[nixflix](https://github.com/kiriwalawren/nixflix)** flake (already an input, pinned 2026-07-28) | Vanilla `services.{sonarr,radarr,…}` — loses declarative API config, no built-in VPN namespacing, more glue to write |
| Player | **Jellyfin** via `nixflix.jellyfin` | Plex — proprietary, requires account |
| Requests | **Jellyseerr** (`nixflix.seerr`) | Overseerr — same code, worse Jellyfin integration |
| Download client | **qBittorrent** (`nixflix.torrentClients.qbittorrent`) | SABnzbd — Usenet costs extra; Deluge — less active upstream |
| VPN | `nixflix.vpn` (WireGuard in a `wg` netns via `Maroka-chan/VPN-Confinement`) | Host-wide VPN — breaks LAN reachability; Gluetun in Docker — off-Nix |
| Subtitles | **Bazarr** (`nixflix.bazarr`) | Manual — not an option |
| Guides sync | **Recyclarr** (`nixflix.recyclarr`) | TRaSH-guides by hand — will drift within a month |
| Domotique platform | **Home Assistant** (`services.home-assistant`) | Home Assistant OS — not NixOS |
| MQTT broker | **Mosquitto** (`services.mosquitto`) | EMQX — overkill for one HA instance |
| Zigbee | **Zigbee2MQTT** (`services.zigbee2mqtt`) with USB coordinator | ZHA — locked to HA lifetime; harder to expose over MQTT |
| ESP devices | **ESPHome** dashboard (`services.esphome`) | Tasmota — less integrated with HA |
| Matter | **matter-server** (`services.matter-server`) | HA built-in — currently requires an external server anyway |
| Reverse proxy | Existing `services.nginx` + Gary landing page | Caddy — nginx already wired for ACME |
| Backend DB | Existing `nixflix.postgres` | SQLite — arr services suffer with SQLite under load |

## 2. Module layout

```
modules/
├── generic/
│   └── gary.nix                                   # add featureFlags + services entries for the new subdomains
└── nixos.gary/
    ├── home-assistant.nix                         # extend: extraComponents, customComponents, customLovelaceModules, trusted_proxies fix
    ├── home-assistant-integrations.nix   [NEW]    # arr/jellyfin/qbit sensors + Hassarr custom component + dashboard views
    ├── mosquitto.nix                     [NEW]    # MQTT broker w/ SOPS password, LAN-only
    ├── zigbee2mqtt.nix                   [NEW]    # z2m service + frontend
    ├── esphome.nix                       [NEW]    # ESPHome dashboard
    ├── matter-server.nix                 [NEW]    # matter-server for Thread/Matter
    ├── nixflix.nix                                # extend: bazarr, qbittorrent, recyclarr, jellyfin plugins
    ├── nixflix-vpn.nix                   [NEW]    # nixflix.vpn wiring, confines qBittorrent + Prowlarr
    ├── reverse-proxy.nix                          # (no change — subdomains auto-derived from services attrset)
    └── secrets.nix                                # add mqtt-broker-password, wireguard-mullvad-conf, hassarr-tmdb-api-key
```

## 3. HACS-only integrations — Nix packaging

None of the arr-flavoured HACS cards/integrations are in nixpkgs. We
package them under `modules/home-manager/ai/skills/` — no, wrong tree
— under `pkgs/home-assistant-arr/` as `callPackage` derivations and
expose them via an overlay so `pkgs.home-assistant-custom-components`
and `pkgs.home-assistant-custom-lovelace-modules` gain new attrs.

Packages to add (all `fetchFromGitHub` + tiny build):

| Attr path | Source | Type |
|---|---|---|
| `home-assistant-custom-components.hassarr` | [TegridyTate/Hassarr](https://github.com/TegridyTate/Hassarr) | HA integration (Python) |
| `home-assistant-custom-lovelace-modules.arr-stack-card` | [martinargalas/ha-arr-stack-card](https://github.com/martinargalas/ha-arr-stack-card) | JS bundle |
| `home-assistant-custom-lovelace-modules.upcoming-media-card-jellyfin` | [mthanhtran/upcoming-media-card-jellyfin](https://github.com/mthanhtran/upcoming-media-card-jellyfin) | JS bundle |
| `home-assistant-custom-lovelace-modules.hassarr-media-search-card` | [SpaceFrags/hassarr-media-search-card](https://github.com/SpaceFrags/hassarr-media-search-card) | JS bundle |

Lovelace bundles are ~30-line derivations: fetch, copy the built `.js`
into `$out/`, done. Hassarr is one `buildHomeAssistantComponent` call.

## 4. Reverse-proxy additions

The existing `mkVirtualHost` fold in `nixos.gary/reverse-proxy.nix`
auto-generates a vhost for each entry in `systemConstants.gary.services`
where `enable = true`. So the plan is: **add entries to `gary.nix`**, no
code changes in `reverse-proxy.nix`.

New entries:

```nix
mqtt = {
  # No HTTP proxy — MQTT is 1883/tcp direct on LAN. Track here for the
  # landing page + firewall, use `enable = false` for nginx.
  enable = false;
  port = 1883;
  subdomain = "mqtt";
  description = "Mosquitto MQTT broker (tcp://mqtt.gary.local:1883)";
};
zigbee2mqtt = { enable = true; port = 8080; subdomain = "zigbee2mqtt"; description = "Zigbee2MQTT"; extraNginxConfig = ""; };
esphome    = { enable = true; port = 6052; subdomain = "esphome";    description = "ESPHome Dashboard"; extraNginxConfig = ""; };
bazarr     = { enable = true; port = 6767; subdomain = "bazarr";     description = "Bazarr Subtitles"; extraNginxConfig = ""; };
qbittorrent = { enable = true; port = 8112; subdomain = "qbittorrent"; description = "qBittorrent"; extraNginxConfig = ""; };
```

The `mqtt` entry is a compromise — it's not HTTP so the current
`mkVirtualHost` can't handle it. Options:
1. Skip nginx for MQTT, still list it on the landing page (this plan)
2. Extend `mkVirtualHost` to support a `kind = "tcp"` variant
3. Add a `stream {}` block to nginx

Choosing (1) for now; option (2) is a follow-up bead if we grow more
non-HTTP services.

## 5. Feature-flag layout

```nix
featureFlags = {
  # existing…
  acme = true;
  adguard = true;
  bluetoothHub = true;
  homeAssistant = true;
  airplay = true;
  # new…
  nixflix         = true;   # was false — re-enable, upstream option shapes match now
  nixflixVpn      = false;  # opt-in — requires wg conf in SOPS first
  mosquitto       = true;
  zigbee2mqtt     = false;  # opt-in — requires USB coordinator plugged in
  esphome         = true;
  matterServer    = false;  # opt-in — Thread border router optional
  haArrIntegration = true;  # HACS-packaged cards + Hassarr component
};
```

Opt-in flags (`nixflixVpn`, `zigbee2mqtt`, `matterServer`) stay off
until user provides prerequisites. This means the first deploy is
safe — no service starts that can't reach its hardware/secret.

## 6. Home Assistant dashboard additions

New Lovelace view "Media" appended to the existing `lovelaceConfig.views`:

- **Chip row** (mushroom-chips-card): Sonarr queue, Radarr queue, qBit
  down/up rate, Jellyfin now-playing count, disk % used
- **Now playing** (mini-media-player): `media_player.jellyfin`
- **Upcoming** (upcoming-media-card-jellyfin): sensor.sonarr_upcoming +
  sensor.radarr_upcoming
- **Downloads** (arr-stack-card): live view of qBit + Sonarr/Radarr queues
- **Request** (hassarr-media-search-card): TMDB search + one-click add
- **History** (apexcharts-card): episodes/movies downloaded per day, 30d

## 7. Automations added

Beyond existing sunset/night/party/away scenes, add:

1. **Download failure alert** — trigger on `sensor.sonarr_queue` state
   including "failed", action: persistent notification + `flash_lights`
2. **Movie Time enhanced** — extend existing scene: also
   `media_player.play_media` on `media_player.jellyfin_living_room` (only
   if the entity exists and `input_boolean.movie_mode` is on)
3. **New release notification** — on any `state_changed` for
   `sensor.sonarr_upcoming` where a new entry appears within 24h, ping
   `mobile_app.<phone>` (guarded by `input_boolean.notify_new_releases`)

## 8. Deployment sequence

Because gary is a live host, deploy in five stages, each independently
reversible with `xi rollback`:

1. **Stage A — Home Assistant "fancy" (safe)**
   - Add mosquitto, esphome, matter-server (opt-in), extra HA
     components, nixpkgs lovelace modules, fix `trusted_proxies`.
   - No new dependencies (Zigbee coordinator optional, matter optional).
   - Expected diff: ~150 lines.

2. **Stage B — Nixflix re-enable + arr completion**
   - Flip `featureFlags.nixflix = true`.
   - Extend `nixflix.nix` with bazarr, qbittorrent, recyclarr, jellyfin
     plugins (Intro Skipper, Playback Reporting), PostgreSQL backend.
   - Expected diff: ~80 lines.

3. **Stage C — HA ↔ arr integration**
   - New module `home-assistant-integrations.nix`.
   - Package HACS cards + Hassarr as an overlay.
   - Add Media dashboard view.
   - Expected diff: ~250 lines.

4. **Stage D — Zigbee2MQTT** (only after user plugs in coordinator)
   - Enable `zigbee2mqtt` flag, wire it to mosquitto.
   - Expected diff: ~50 lines.

5. **Stage E — VPN kill-switch** (only after user provides `wireguard-mullvad-conf`)
   - Enable `nixflixVpn` flag, confine qBittorrent + Prowlarr.
   - Expected diff: ~40 lines.

## 9. Validation

Between each stage:

```bash
nix flake check
nix build .#nixosConfigurations.gary.config.system.build.toplevel
xi os switch . -H gary        # user runs, agent does not push
# after boot:
systemctl --failed
journalctl -b -p err
```

## 10. Rollback

Every stage is one commit. Each commit is idempotent: reverting to
the previous flake generation via `xi rollback` restores the
previous service set cleanly (systemd stops the new units, deleted
state dirs stay on disk — nixflix uses `/data/.state/nixflix` which
survives across rollbacks).

## 11. Risks

| Risk | Mitigation |
|---|---|
| nixflix alpha status — option shapes may break at next input update | Pin the input rev; only bump on user request |
| VPN misconfiguration silently leaks | `nixflix.vpn` uses `Maroka-chan/VPN-Confinement` netns — no fallback route by design |
| PostgreSQL schema changes between arr versions | nixflix ships upstream schemas; arr services do their own migrations |
| Zigbee coordinator absent → z2m boot loop | Feature flag off by default |
| Matter server needs Thread border router for Thread devices | Feature flag off by default; Wi-Fi Matter devices work without |
| HACS custom components unmaintained / broken by HA upgrade | Pinned by commit SHA in the packaging; can be disabled independently of Hass |
| MQTT broker with weak password on LAN | SOPS-provisioned password; broker binds `127.0.0.1` + LAN interface only |

## 12. Beads decomposition

Existing coarse beads (created earlier this session):

- `dotfiles-w60` — HA "fancy" (MQTT, Zigbee2MQTT, ESPHome, Matter, custom components, lovelace) — maps to Stage A
- `dotfiles-5xj` — nixflix arr stack completion — maps to Stage B
- `dotfiles-0sd` — VPN kill-switch — maps to Stage E

Run this to add the finer-grained beads and dependency edges (agent
sandbox blocks `bd` mid-session; run as `! bd …` or plain shell):

```bash
# --- Stage A leaves ---
A1=$(bd q "gary: mosquitto MQTT broker w/ SOPS password" --priority high)
A2=$(bd q "gary: zigbee2mqtt service + frontend (feature-flagged off)" --priority medium)
A3=$(bd q "gary: esphome dashboard" --priority medium)
A4=$(bd q "gary: matter-server (feature-flagged off)" --priority low)
A5=$(bd q "gary: HA extraComponents + customLovelaceModules (mushroom, mini-graph, apexcharts, button-card, card-mod, bubble-card)" --priority high)
A6=$(bd q "gary: fix HA trusted_proxies to include LAN IP" --priority high)
A7=$(bd q "gary: add mqtt/zigbee2mqtt/esphome/bazarr/qbittorrent to gary.services attrset" --priority high)
bd link dotfiles-w60 $A1
bd link dotfiles-w60 $A2
bd link dotfiles-w60 $A3
bd link dotfiles-w60 $A4
bd link dotfiles-w60 $A5
bd link dotfiles-w60 $A6
bd link dotfiles-w60 $A7

# --- Stage B leaves ---
B1=$(bd q "gary: re-enable featureFlags.nixflix" --priority high)
B2=$(bd q "gary: add nixflix.bazarr" --priority high)
B3=$(bd q "gary: add nixflix qbittorrent torrent client" --priority high)
B4=$(bd q "gary: add nixflix.recyclarr TRaSH-guides sync" --priority medium)
B5=$(bd q "gary: enable Jellyfin plugins (Intro Skipper, Playback Reporting)" --priority medium)
bd link dotfiles-5xj $B1
bd link dotfiles-5xj $B2
bd link dotfiles-5xj $B3
bd link dotfiles-5xj $B4
bd link dotfiles-5xj $B5
bd link $B2 $B1   # bazarr needs nixflix re-enabled
bd link $B3 $B1
bd link $B4 $B1

# --- Stage C: HA↔arr integration (new parent) ---
C=$(bd create --title="gary: HA↔arr integration — HACS cards + Hassarr + Media dashboard" --type=feature --priority=medium --description="Package HACS-only components as Nix derivations; add Media lovelace view showing arr queues, Jellyfin now-playing, TMDB search")
C1=$(bd q "pkgs: package Hassarr as buildHomeAssistantComponent" --priority medium)
C2=$(bd q "pkgs: package ha-arr-stack-card lovelace bundle" --priority medium)
C3=$(bd q "pkgs: package upcoming-media-card-jellyfin bundle" --priority medium)
C4=$(bd q "pkgs: package hassarr-media-search-card bundle" --priority low)
C5=$(bd q "gary: home-assistant-integrations.nix — enable sensors, Media view, arr automations" --priority medium)
bd link $C $C1
bd link $C $C2
bd link $C $C3
bd link $C $C4
bd link $C $C5
bd link $C5 $C1   # dashboard uses hassarr entity
bd link $C dotfiles-5xj  # arr stack must exist first
bd link $C dotfiles-w60  # HA foundation must exist first

# --- Stage D: Zigbee2MQTT (child of A2, opt-in) ---
# Nothing extra — A2 covers it once user plugs a USB coordinator.

# --- Stage E leaves ---
E1=$(bd q "gary: SOPS wireguard-mullvad-conf secret slot" --priority medium)
E2=$(bd q "gary: nixflix-vpn.nix — confine qBittorrent + Prowlarr in wg netns" --priority medium)
bd link dotfiles-0sd $E1
bd link dotfiles-0sd $E2
bd link $E2 $E1
bd link dotfiles-0sd dotfiles-5xj  # VPN needs arr stack live
```

After running, `bd ready` will surface **A1, A5, A6, A7** first (no
blockers), then A2/A3/A4 (independent), then Stage B/C/E once their
parents unblock.

