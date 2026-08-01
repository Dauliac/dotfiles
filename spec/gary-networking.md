# Gary: networking layer — Specification

Status: proposed
Owner: dauliac
Supersedes: [gary-public-exposure.md](gary-public-exposure.md) (was
too narrow — this spec covers the whole networking layer)
Depends on: [gary-media-domotique.md](gary-media-domotique.md) — that
spec declares the service inventory; this spec routes it.

## User-visible outcome

**One URL, three access paths, one truth.**

For every service on gary, there is exactly one URL under
`j4rd1.cloud`. From that URL, the user can reach the service through
whichever path is available:

1. **On the couch** (LAN): the URL resolves to gary's LAN IP via
   AdGuard. Direct TCP over ethernet/WiFi. No third party involved.
2. **On the plane** (VPN — Tailscale): laptop is a tailnet member.
   `j4rd1.cloud` queries go to gary's AdGuard through the tailnet,
   get the LAN IP back, traffic routes via Tailscale's subnet router.
3. **From any browser** (public — Cloudflare Tunnel): only
   allowlisted services (Jellyfin, Home Assistant, Jellyseerr) have a
   public DNS record. Traffic terminates at Cloudflare's edge and
   routes to gary via an outbound-only tunnel.

Path 1 and Path 2 both terminate at nginx bound to the LAN IP.
Path 3 terminates at nginx bound to `0.0.0.0`. Same wildcard TLS
certificate served on all paths.

## Access tiers

Each service is tagged with one of two tiers. The tier determines
where the URL is reachable from.

### Tier `public`

Reachable from: internet, tailnet, LAN.
DNS: public CNAME → CF Tunnel edge; AdGuard rewrite for LAN/tailnet.
Nginx: listens on `0.0.0.0:443`.
Cloudflare Tunnel: has an ingress rule.

Services in this tier:

- Jellyfin — native auth, mobile apps expect WAN
- Home Assistant — auth + 2FA + Companion app
- Jellyseerr — native auth + optional Jellyfin SSO

### Tier `private`

Reachable from: tailnet, LAN. **Not** from the public internet.
DNS: **no** public record; AdGuard rewrite for LAN/tailnet.
Nginx: listens on `[gary.network.lanIP]:443` — public interface
never sees the vhost.
Cloudflare Tunnel: **no** ingress rule.

Services in this tier:

- AdGuard admin UI
- Sonarr, Radarr, Lidarr, Prowlarr, Bazarr — shared-secret auth,
  historical CVEs, don't expose
- qBittorrent WebUI
- Zigbee2MQTT, ESPHome
- Mosquitto (tcp, no HTTP — private by construction)

## Ad-blocking on the LAN

Every DNS query from a device that uses `10.10.0.12:53` (gary's
AdGuard) goes through the blocklist set already declared in
`systemConstants.gary.adguard.blocklists`. Ads and trackers are
NXDOMAINed at resolution time — the device never opens a TCP
connection to the ad server.

## Certificate

One wildcard cert `*.j4rd1.cloud` + `j4rd1.cloud` SAN, from Let's
Encrypt via DNS-01 through Cloudflare API. Used on **all three
paths** — LAN, tailnet, public. Individual subdomain names never
appear in Certificate Transparency logs (wildcard hides them).

## Non-goals

- **No zero-trust auth proxy** (Authelia, Authentik, CF Access) in
  this spec. Services use their own auth. Add a separate spec if
  admin panels need SSO.
- **No IPv6-only path** — dual-stack works via CF and Tailscale
  transparently, no separate configuration.
- **No dynamic-DNS client** — CF Tunnel eliminates the need; the
  port-forward alternative is out-of-scope here.
- **No mDNS / .local exposure** past the LAN — `gary.local` is
  retired.
- **No LAN client provisioning automation** — router DHCP option 6
  (DNS = 10.10.0.12) is a manual prerequisite.
- **No mesh VPN between multiple homes** — single-user tailnet only.

## Acceptance criteria

Feature is done when, on freshly-deployed gary + a laptop with
Tailscale installed and a phone with mobile data:

**Same URL, three paths:**

1. `dig +short jellyfin.j4rd1.cloud @10.10.0.12` from laptop on LAN
   → returns `10.10.0.12`.
2. Laptop on hotel WiFi, connected to tailnet:
   `dig +short jellyfin.j4rd1.cloud` (via Tailscale MagicDNS split)
   → returns `10.10.0.12`, traffic routes via tailnet.
3. Phone on mobile data:
   `dig +short jellyfin.j4rd1.cloud @1.1.1.1` → CF tunnel CNAME.
4. `curl -sSf https://jellyfin.j4rd1.cloud/health` returns 200 from
   all three paths.
5. TLS fingerprint matches on all three paths
   (`openssl s_client -showcerts | openssl x509 -fingerprint`).

**Tier isolation:**

6. Phone on mobile data:
   `curl -sSf https://sonarr.j4rd1.cloud/` returns connection
   refused / NXDOMAIN. Verified: no public DNS record + no CF Tunnel
   ingress route.
7. Laptop on tailnet: `curl -sSf https://sonarr.j4rd1.cloud/` returns
   200 (Sonarr login page) — private tier is tailnet-reachable.
8. LAN: same as (7) — private tier is LAN-reachable.

**Ad-blocking:**

9. LAN laptop:
   `dig doubleclick.net @10.10.0.12` returns `0.0.0.0` or NXDOMAIN.
10. Tailnet laptop (via subnet-routed AdGuard): same behavior.

**Certificate:**

11. `openssl x509 -in /var/lib/acme/j4rd1.cloud/fullchain.pem -noout -text`
    shows: subject `j4rd1.cloud`, SAN `DNS:j4rd1.cloud, DNS:*.j4rd1.cloud`,
    issuer Let's Encrypt.
12. CT log search for `sonarr.j4rd1.cloud` returns no entries (wildcard
    obscures subdomain names).

**Systemd:**

13. `systemctl is-active nginx acme-j4rd1.cloud.timer tailscaled cloudflared`
    → all `active`.

**Nix build:**

14. `nix flake check` and
    `nix build .#nixosConfigurations.gary.config.system.build.toplevel`
    succeed.

## Public repository — every secret goes through SOPS

`Dauliac/dotfiles` is public. Nothing sensitive can be committed as
plaintext. All the identifiers below are either encrypted at rest via
`sops-nix` or acceptable to publish.

| Value | Class | Delivery |
|---|---|---|
| Cloudflare API token (for DNS-01) | **Secret** | SOPS `acme-cloudflare-token` |
| Cloudflare Tunnel credentials JSON | **Secret** | SOPS `cloudflared-credentials` |
| Cloudflare Tunnel UUID | Semi-sensitive | SOPS `cloudflared-tunnel-uuid` (defense in depth — routing without the credentials JSON is impossible, but grep-hygiene matters) |
| Tailscale pre-auth key | **Secret** | SOPS `tailscale-authkey` |
| Tailscale tailnet name (e.g. `foo-bar.ts.net`) | Semi-sensitive | SOPS `tailscale-tailnet` |
| Let's Encrypt account email | Public | Nix source (`gary.acme.email`) — visible in cert issuance logs anyway |
| Domain name `j4rd1.cloud` | Public | Nix source — already in public DNS |
| LAN CIDR `10.10.0.0/24` | Public | Nix source — RFC1918, meaningless outside LAN |
| Gary's LAN IP `10.10.0.12` | Public | Nix source — same reason |
| Gary's tailnet IP `100.x.y.z` | Public (per-node) | Nix source if hardcoded, but prefer runtime discovery |
| SSH host public key | Public | Nix source (`ssh_host_*_key.pub`) |
| Gary's user hashed passwords | **Secret** | SOPS (existing `gary_hashed_password`, `dauliac_hashed_password`) |

**Verification** before every commit that touches `spec/`, `plan/`,
`memory/`, or any `.nix` file:

```bash
git diff --cached | grep -iE '(token|password|secret|apikey|api_key|priv|BEGIN.*PRIVATE)'
```

Non-empty output = stop and rewrite.

## Out-of-band prerequisites

Before deployment, `dauliac` must:

1. Cloudflare API token scoped to zone `j4rd1.cloud`
   (`Zone.Zone:Read` + `Zone.DNS:Edit`) → SOPS `acme-cloudflare-token`.
2. Cloudflare Tunnel `gary` created; credentials JSON → SOPS
   `cloudflared-credentials`; UUID → `systemConstants.gary.cloudflareTunnel.uuid`.
3. Cloudflare zone: per-public-service CNAME (not a wildcard) so
   private tier stays off public DNS. Example:
   `jellyfin.j4rd1.cloud CNAME <uuid>.cfargotunnel.com`.
4. Tailscale account + auth key (reusable, pre-approved for
   auto-approve of subnet route `10.10.0.0/24`) → SOPS
   `tailscale-authkey`.
5. Router DHCP option 6 = `10.10.0.12`. Verify on a LAN client with
   `resolvectl status | grep DNS`.
6. Tailscale ACL (in Tailscale admin, or committed as
   `tailscale-policy.hujson` if using Headscale) grants gary the
   `tag:server` tag with subnet-route approval.
