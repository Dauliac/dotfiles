# Gary: public exposure with split-horizon DNS — Specification

> **⚠️ SUPERSEDED** by [gary-networking.md](gary-networking.md).
> That spec covers the whole networking layer (public + VPN + LAN),
> replaces the two-mode WAN model here with a per-service tier model,
> and hardens the public-repo secret-handling posture.
> Keep this file as history; do not extend.

Status: superseded 2026-08-01
Owner: dauliac
Depends on: [spec/gary-media-domotique.md](gary-media-domotique.md) —
this spec **amends** its "no public exposure" non-goal.

## User-visible outcome

The same URL works from anywhere:

- On the couch: `https://jellyfin.j4rd1.cloud` — resolves via AdGuard to
  `10.10.0.12`, connects to gary over LAN, TLS handshake completes with
  a Let's Encrypt certificate.
- On mobile data: `https://jellyfin.j4rd1.cloud` — resolves via
  Cloudflare to a tunnel edge, request egresses to gary via
  `cloudflared`, same TLS certificate, same content.

LAN devices additionally benefit from AdGuard ad-blocking on every
lookup — advertisements are stripped at DNS resolution time before the
device ever sees them.

## Services exposed to the internet

Allowlist. Anything not on this list is LAN-only.

| Service | URL | Reason it's safe |
|---|---|---|
| Jellyfin | `jellyfin.j4rd1.cloud` | Native auth, active project, mobile apps expect WAN |
| Jellyseerr | `jellyseerr.j4rd1.cloud` | Native auth + optional Jellyfin SSO |
| Home Assistant | `hass.j4rd1.cloud` | Robust auth + 2FA, Companion app needs WAN |

## Services that stay LAN-only

Any URL for these fails from the internet — the tunnel has no route,
the router forwards no port, the LAN vhost binds to the LAN interface
only.

- `adguard.j4rd1.cloud` — admin panel
- `sonarr.j4rd1.cloud`, `radarr.j4rd1.cloud`, `lidarr.j4rd1.cloud`,
  `prowlarr.j4rd1.cloud`, `bazarr.j4rd1.cloud`
- `qbittorrent.j4rd1.cloud`
- `zigbee2mqtt.j4rd1.cloud`, `esphome.j4rd1.cloud`
- `mosquitto` (tcp, not HTTP)

## Split-horizon guarantee

For every URL in the allowlist:

1. From the LAN (any device using AdGuard for DNS), traffic **must not
   leave the LAN**. Verified with `mtr --tcp -P 443 jellyfin.j4rd1.cloud`
   showing exactly one hop.
2. From the internet, traffic **must** reach gary via the Cloudflare
   Tunnel (or, if the tunnel is disabled, via the router port-forward).
3. The Let's Encrypt certificate served is the **same** on both paths
   (`openssl s_client -showcerts` fingerprint matches).

## Ad-blocking

LAN clients configured to use gary's AdGuard (`10.10.0.12:53`) get:

- The blocklist set already declared in `systemConstants.gary.adguard.blocklists`
  (AdGuard DNS filter, AdAway, StevenBlack, OISD, Phishing Army, NoCoin,
  EasyPrivacy, Prigent Ads).
- Encrypted upstream (DoH to Cloudflare + Google in parallel).
- No leaks — split-horizon rewrites resolve internal names locally, they
  never hit upstream resolvers.

## Non-goals

- **No zero-trust gateway** in this pass (Cloudflare Access, Authelia,
  Authentik) — services rely on their own auth. Zero-trust is a separate
  spec if needed.
- **No IPv6 exposure** — CF Tunnel handles v6 transparently; direct
  port-forward stays IPv4-only for now.
- **No email or LDAP** — no self-hosted mail, no directory service.
- **No dynamic DNS client** (ddclient, etc.) — Cloudflare Tunnel makes
  the WAN IP irrelevant. If port-forward mode is chosen, user provides
  a static WAN IP or DDNS via router.

## Acceptance criteria

Feature is done when, on a freshly-deployed gary:

1. Wildcard cert `*.j4rd1.cloud` + `j4rd1.cloud` exists at
   `/var/lib/acme/j4rd1.cloud/fullchain.pem`, not expired, matches CF
   DNS record `TXT _acme-challenge.j4rd1.cloud` for the last renewal.
2. `dig +short jellyfin.j4rd1.cloud @10.10.0.12` returns `10.10.0.12`.
3. `dig +short jellyfin.j4rd1.cloud @1.1.1.1` returns a Cloudflare
   tunnel edge IP (or the port-forwarded WAN IP if that mode is on).
4. `curl -sSf https://jellyfin.j4rd1.cloud/health` returns 200 both
   from the LAN and from an external network (mobile data).
5. `curl -sSf https://sonarr.j4rd1.cloud/` from mobile data returns
   TCP timeout / connection refused (verified LAN-only).
6. `curl -sSf https://adguard.j4rd1.cloud/` from mobile data returns
   TCP timeout / connection refused.
7. `systemctl is-active cloudflared nginx acme-j4rd1.cloud.timer`
   all return `active`.
8. `nix flake check` and
   `nix build .#nixosConfigurations.gary.config.system.build.toplevel`
   succeed with the new modules.

## Out-of-band prerequisites (user-provided)

Before deployment, `dauliac` must:

1. Create a Cloudflare API token scoped to `j4rd1.cloud` zone with
   permissions `Zone.Zone:Read` + `Zone.DNS:Edit`. Place in SOPS as
   `acme-cloudflare-token`. (May already exist if ACME is currently
   configured — check `secrets/passwords/`.)
2. In the Cloudflare dashboard, create a Tunnel named `gary`, download
   its credentials JSON, place in SOPS as `cloudflared-credentials`.
   Record the tunnel UUID.
3. Add a CNAME record `*.j4rd1.cloud → <tunnel-uuid>.cfargotunnel.com`
   in the Cloudflare zone. (Or per-subdomain CNAMEs if the allowlist
   should be enforced at the DNS layer as well — belt-and-braces.)
4. Configure the LAN router to hand out `10.10.0.12` as DHCP DNS
   (option 6). Verify on a LAN client:
   `nmcli device show | grep DNS` returns `10.10.0.12`.
5. Fetch a TMDB v3 API key (for Hassarr, if enabling
   `haArrIntegration`) → SOPS `hassarr-tmdb-api-key`.
