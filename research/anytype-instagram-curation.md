# Anytype x Instagram Curation Pipeline — Primary-Source Research

Scope: informing a tool that (a) backfills existing Instagram Saved posts into an Anytype
Collection, and (b) provides a low-friction mobile share flow for adding new links on the fly.

Convention note: this repo has no pre-existing `research/` or `notes/` directory. Prior "docs" live
under `docs/statewright/` and design plans under `plan/`, but neither is a natural home for
external-tooling investigation. This file is placed at `research/anytype-instagram-curation.md`
following the default in the request.

All non-trivial claims below cite a primary source — official docs, first-party repos, or
the actual OpenAPI/protobuf. Where a secondary source was the only pointer, the primary source
was fetched and verified before quoting.

---

## 1. Anytype integration surface

### 1.1 What is currently shippable (late 2025 / early 2026)

Anytype ships an **official, versioned, local-first REST API** as part of the desktop client.
It is the recommended integration surface — not `anytype-heart` directly, not the mnemonic-based
account flow.

- **Name:** Anytype API / "Local API"
- **Introduced:** desktop client v0.46.x
  ([doc.anytype.io Local API page](https://doc.anytype.io/anytype/features/integrations/local-api.md))
- **Current API version identifier:** `2025-11-08`
  ([developers.anytype.io reference index](https://developers.anytype.io/docs/reference))
- **Base URL:** `http://localhost:31009/v1/` (loopback only)
  ([developers.anytype.io auth guide](https://developers.anytype.io/docs/guides/get-started/authentication))
- **Transport:** HTTP + JSON. Bearer-token auth via `Authorization: Bearer <api_key>`.
  Every request also requires `Anytype-Version: 2025-11-08`. Source: same auth guide.
- **Desktop app required:** yes. The API is embedded inside the desktop client process; the
  documentation is explicit that it "is now available and directly included with the desktop app"
  and "operates entirely on localhost"
  ([Local API doc](https://doc.anytype.io/anytype/features/integrations/local-api.md)).
- **Developer portal repo:** [`anyproto/anytype-api`](https://github.com/anyproto/anytype-api)
  (docs + OpenAPI spec, MIT'd Docusaurus site). OpenAPI YAML lives at
  [`docs/reference/openapi-2025-11-08.yaml`](https://raw.githubusercontent.com/anyproto/anytype-api/main/docs/reference/openapi-2025-11-08.yaml).

### 1.2 anytype-heart — the Go middleware

- Repo: [`anyproto/anytype-heart`](https://github.com/anyproto/anytype-heart)
- Described as "shared library for Anytype clients"; distributed as part of desktop apps rather
  than as a standalone server.
- License: **Any Source Available License 1.0** (source-available, not OSI-open — this is a real
  redistribution constraint if you want to package it yourself).
- **gRPC surface exists.** Entry point is `cmd/grpcserver/grpc.go`; by default binds
  `ANYTYPE_GRPC_ADDR=:31007` and gRPC-Web on `ANYTYPE_GRPCWEB_ADDR=:31008`.
- Service definition:
  [`pb/protos/service/service.proto`](https://github.com/anyproto/anytype-heart/blob/main/pb/protos/service/service.proto)
  defines the `ClientCommands` service with 200+ RPCs including `ObjectCreate`,
  `ObjectCreateBookmark`, `BlockBookmarkCreateAndFetch`, `WorkspaceObjectListAdd`.
- **Recommendation:** ignore gRPC for this project. It is undocumented for third parties, tied to
  the desktop process anyway, and the REST API above wraps the useful subset with a stable version
  header. Reach for `service.proto` only if the REST API is missing something (e.g. explicit
  "reload from source" for a Bookmark — that's `BlockBookmarkCreateAndFetch`, not `ObjectCreate`).

### 1.3 Authentication flow (verbatim, from the auth guide)

Two supported paths — both end in a bearer token:

**Path A — user generates in-app (frictionless for a personal tool):**
Settings → API Keys → Create new. Use the key as `Authorization: Bearer <api_key>`.

**Path B — challenge/response (for redistributable integrations):**

```
POST http://localhost:31009/v1/auth/challenges
Content-Type: application/json
Anytype-Version: 2025-11-08
{ "app_name": "insta-curation" }
→ { "challenge_id": "..." }
```

Desktop pops a 4-digit code. Exchange it:

```
POST http://localhost:31009/v1/auth/api_keys
{ "challenge_id": "...", "code": "1234" }
→ { "api_key": "..." }
```

Source: [Authentication guide](https://developers.anytype.io/docs/guides/get-started/authentication).

### 1.4 Object model for bookmark curation

Terms — from primary docs:

- **Space** = top-level tenant / vault ([API reference structure](https://developers.anytype.io/docs/reference)).
- **Object type** = a schema. `Bookmark` is a **built-in System Type**
  ([community.anytype.io on Source relation](https://community.anytype.io/t/source-relation-bookmark-cant-be-re-used/11612),
  cross-checked with [Bookmarks doc](https://doc.anytype.io/anytype/create/bookmarks)).
- **Bookmark object** — first-class Object, not a block. Auto-fetches title, favicon, preview
  image, description when given a Source URL
  ([Bookmarks doc](https://doc.anytype.io/anytype/create/bookmarks)).
- **Collection vs Set:** Collection is a *manually-populated* container that can hold heterogeneous
  Object types; Set is a *saved query* filtered by type/relation
  ([Collections doc](https://doc.anytype.io/anytype-docs/getting-started/sets/collections)).
  **For "my curated Instagram stuff" → use a Collection**, not a Set.
- **Relation / Property** — a typed field on an object. The Bookmark type ships with a `Source`
  relation (URL) plus title, description, image, favicon; users routinely add `Tag`, `Status`, etc.
- **List** — the API's generic name for Collection-like containers. Endpoints live under
  `/v1/spaces/{space_id}/lists/...`.

### 1.5 Endpoint inventory (from the 2025-11-08 OpenAPI)

Verified against [`openapi-2025-11-08.yaml`](https://raw.githubusercontent.com/anyproto/anytype-api/main/docs/reference/openapi-2025-11-08.yaml):

- `POST /v1/auth/challenges`, `POST /v1/auth/api_keys` — auth flow.
- `GET/POST /v1/spaces`, `GET/PATCH /v1/spaces/{space_id}`.
- `GET/POST /v1/spaces/{space_id}/objects` — list / create.
- `GET/PATCH /v1/spaces/{space_id}/objects/{object_id}`.
- `POST /v1/spaces/{space_id}/lists/{list_id}/objects` — **add existing objects to a
  Collection** (body: `{ "objects": ["obj_id_1", "obj_id_2"] }`).
- `GET/POST /v1/spaces/{space_id}/types`, `GET/POST /v1/spaces/{space_id}/properties`.
- `POST /v1/search` — cross-space text search with filters and sort.
- Also present: Chat, Files, Members, Tags, Templates.

### 1.6 Concrete: creating a Bookmark in a specific Collection

`CreateObjectRequest` schema (fields taken from the OpenAPI):

- **required:** `type_key` (string) — e.g. `"bookmark"`.
- **optional:** `name`, `body` (markdown), `icon`, `properties` (array of
  `PropertyLinkWithValue`), `template_id`.
- The Bookmark type keys off `source_url` via the built-in `source` property; provide it in
  `properties`.

Minimal round-trip:

```bash
# 1. resolve the target Space id
curl -s http://localhost:31009/v1/spaces \
  -H "Authorization: Bearer $ANYTYPE_KEY" \
  -H "Anytype-Version: 2025-11-08" | jq '.data[] | {id, name}'

# 2. create the Bookmark object
curl -s -X POST http://localhost:31009/v1/spaces/$SPACE_ID/objects \
  -H "Authorization: Bearer $ANYTYPE_KEY" \
  -H "Anytype-Version: 2025-11-08" \
  -H "Content-Type: application/json" \
  -d '{
    "type_key": "bookmark",
    "name": "some IG reel",
    "properties": [
      { "key": "source", "url": "https://www.instagram.com/reel/XYZ/" },
      { "key": "tag",    "multi_select": ["instagram", "recipe"] }
    ]
  }' | jq -r '.object.id'
# → returned OBJECT_ID

# 3. append it to the "Instagram saves" Collection (list)
curl -s -X POST http://localhost:31009/v1/spaces/$SPACE_ID/lists/$LIST_ID/objects \
  -H "Authorization: Bearer $ANYTYPE_KEY" \
  -H "Anytype-Version: 2025-11-08" \
  -H "Content-Type: application/json" \
  -d '{ "objects": ["'"$OBJECT_ID"'"] }'
```

Two subtleties worth flagging:

- The **exact** JSON shape of `PropertyLinkWithValue` varies by property type (URL vs
  multi_select vs date etc). The OpenAPI enumerates the discriminants; verify against the live
  spec before shipping code.
- To force Anytype to actually fetch and populate title/description/preview from the URL, you may
  need to call `BlockBookmarkCreateAndFetch` via gRPC — the REST equivalent is not explicitly
  documented as of 2025-11-08. In practice, creating the object with `source` set is usually
  enough because desktop handles the fetch. Worth a smoke test.

### 1.7 Limitations that shape the design

- **Loopback only.** No remote access — a phone can't talk to it directly. Anything mobile has to
  land at a server-side component you own, which then relays to the local API. (Or you tunnel it,
  but that's operationally miserable for a personal tool.)
- **Desktop must be running.** No headless mode is exposed. If the desktop is closed, ingest
  blocks — build a queue.
- **Rate limits exist.** `POST /objects` returns HTTP `423` on rate-limit
  (confirmed via [Create Object reference](https://developers.anytype.io/docs/reference/2025-03-17/create-object/)).
  The specific numeric limits are not published in the doc I could reach; assume "gentle" and
  back off aggressively.
- **License of anytype-heart** (Any Source Available License 1.0) is *not* OSI-open. This does not
  affect calling the REST API but does affect any plan to embed or repackage the middleware.
- **API version pinning.** Every request carries `Anytype-Version`. Pin it in your client and
  re-verify on each Anytype desktop upgrade.

### 1.8 Community wrappers

- [`anyproto/anytype-mcp`](https://github.com/anyproto/anytype-mcp) — **official** MCP server
  (MIT). Wraps the local REST API on `http://127.0.0.1:31009` and generates MCP tools from the
  OpenAPI spec. Actively developed. Categories exposed: Global & Space Search, Spaces & Members,
  Objects & Lists, Properties & Tags, Types & Templates. This is the right thing to point Claude
  Code / other agents at, but it is not the right thing for a headless ingest pipeline (which
  should hit REST directly).
- [`anyproto/anytype-cli`](https://github.com/anyproto/anytype-cli) — Go CLI, also official.
- Python `anytype-api` PyPI packages: multiple exist and most are outdated wrappers of pre-2025
  gRPC. Do **not** rely on them — the REST API is stable enough now that writing a thin `httpx`
  client (~150 LOC) is a better bet than adopting a third-party wrapper.

---

## 2. Instagram saved-posts extraction

### 2.1 Landscape summary, ranked by legitimacy + durability

| Path | Legitimacy | Durability | Verdict for this project |
| --- | --- | --- | --- |
| Meta DYI (Download Your Information) | Official | High | **Backfill ground truth** |
| Instagram Graph API / Basic Display API | Official | High | **Not usable** — no saved-posts endpoint |
| `instaloader :saved` | Unofficial, tolerated | Medium | Fallback / periodic re-sync |
| `arc298/instagram-scraper` | Unofficial | Low | **Do not adopt** — discontinued |
| Browser extensions ("Saved Posts Exporter" etc.) | Unofficial | Low-Medium | Emergency backfill only |
| Apify / SociaVault / paid scrapers | Paid, ToS-grey | Medium | Not for personal use |

### 2.2 Meta's Download Your Information — the ground truth path

- Location: **Settings → Accounts Center → Your information and permissions → Download your
  information**. Choose `Some of your information → Saved`, format `JSON`, date range `All time`.
  Cross-verified by [PIRG guide](https://pirg.org/resources/how-to-request-and-download-instagram-data/)
  which walks through the official flow.
- Format: JSON is machine-readable and is the recommended pick for downstream tooling.
- **Contents of `saved_posts.json`:** a list of `{link, timestamp}` pairs — pointers only. **No
  captions, no media, no author, no thumbnail.** The media belongs to other users, so Meta
  legitimately exports a link and a timestamp and nothing else
  ([Marqly overview](https://www.marqly.com/blog/export-instagram-saved-posts) — verified by the
  DYI shape).
- Collections: saved-post *Collections* are exported alongside as a separate section of the
  archive (grouped list of the same `{link, timestamp}` structure per Collection). Verify this on
  first export; Meta has shuffled section names before.
- **Latency:** typically hours; up to 48h; documented ceiling **30 days** for huge accounts
  ([igeeksblog](https://www.igeeksblog.com/how-to-download-view-your-instagram-data/), corroborated
  by multiple sources).
- **Link expiry:** email link is valid **4 days** after arrival. Download promptly.

Implication for ingest: DYI gives you a *URL list*. To turn each URL into a rich Bookmark in
Anytype, you rely on Anytype's own URL-fetch — which happens naturally when you create a Bookmark
object with `source` set. No need to scrape captions/media yourself unless you want richer
metadata than what Meta's OG tags plus Anytype's crawler provide.

### 2.3 Instagram Graph API / Basic Display API — confirmed dead end

- The Instagram Graph API is scoped to Business/Creator accounts and returns *your own* media,
  insights on your own media (including a `saved` **count** metric), and comments.
- There is **no endpoint that returns a user's list of saved/bookmarked posts.** The `saved`
  field on `/{ig-media-id}/insights` is a numeric aggregate, not a listing
  ([Meta Graph API insights doc, summarized in 2026 guides](https://elfsight.com/blog/instagram-graph-api-complete-developer-guide-for-2026/);
  the primary Meta docs at graph.facebook.com list no such endpoint).
- The Basic Display API was **deprecated** by Meta in 2024. Even at its peak it did not expose
  saved posts.
- Confirmed: Graph API is not a viable path for this use case.

### 2.4 instaloader (Python) — the pragmatic scraper

- Repo: [`instaloader/instaloader`](https://github.com/instaloader/instaloader),
  MIT-licensed, actively maintained. **Latest release 4.15.3 on 26 Jul 2026**
  ([release page](https://instaloader.github.io/)).
- **Supports `:saved`.** Command form: `instaloader --login=<user> :saved`. Requires login;
  session file is persisted (`~/.config/instaloader/session-<user>`) so 2FA is only entered once
  ([troubleshooting](https://instaloader.github.io/troubleshooting.html) confirms 2FA + checkpoint
  work, and session files "usually do not expire").
- Rate limits: 429s are common; the doc explicitly warns not to restart the process frequently
  because the internal token bucket resets. Design for long-lived processes and honor the
  "Too many queries" soft warning by backing off.
- **URL-only mode isn't a first-class flag.** With `--no-pictures --no-videos --no-captions` you
  still get a `<shortcode>.json` metadata dump per post. Cheaper: use `instaloader` as a Python
  library and iterate `Profile.from_username(L.context, name).get_saved_posts()` to yield `Post`
  objects, then just read `.shortcode` / `.url`. That's the right shape for feeding Anytype.
- **ToS risk:** repo carries the standard "not affiliated with Instagram, use at your own risk"
  disclaimer. Personal-use, low-rate scraping of your own saves is tolerated in practice but
  formally violates Instagram's ToS. Do not distribute credentials, do not scrape at scale, do
  not build a paid product on this.

### 2.5 Other tools looked at

- [`arc298/instagram-scraper`](https://github.com/arc298/instagram-scraper): **discontinued**.
  Skip.
- [`drawrowfly/instagram-scraper`](https://github.com/drawrowfly/instagram-scraper): Node-based,
  no-login, targets public profiles/hashtags — does **not** access your own Saved.
- Chrome "Saved Posts Exporter" extension
  ([listing](https://chromewebstore.google.com/detail/saved-posts-exporter/opgclnehegaekpalmclkdaomgljpbadp))
  scrapes via the logged-in web session and can emit URL lists. Useful as an emergency backfill if
  DYI queues indefinitely; opaque code, treat as throwaway.
- Apify "Instagram Scraper" actor has an [open issue explicitly stating "Saved Posts" export is
  not supported](https://apify.com/apify/instagram-scraper/issues/saved-posts-export-2YaUwNWBleL3mlKis).

### 2.6 Recommendation

- **Backfill = DYI.** Request once, unpack `saved_posts.json`, iterate, POST each to Anytype.
- **Ongoing catch-up (weekly)** = `instaloader :saved` in library mode, deduplicating against the
  already-ingested set in Anytype. Set is easily maintained via `POST /v1/search` on the target
  Collection.
- **Real-time new saves** = do **not** try. It is architecturally the wrong problem; treat it
  via the share flow below instead.

---

## 3. Share-flow mechanisms (mobile → external destination)

Constraint: the pipeline endpoint is loopback on the Linux desktop. Anything mobile has to land
somewhere reachable (a small server on the LAN, a VPS, a WireGuard-exposed host, or a queue).

### 3.1 Android options

| Option | Friction (taps IG→saved) | Reliability | Offline tolerance | Self-hosting requirement |
| --- | --- | --- | --- | --- |
| **HTTP Shortcuts** as share target → your webhook | 3 taps (Share → HTTP Shortcuts → shortcut) | High | Queues on retry if configured | Yes (webhook) |
| Anytype Android share sheet → Bookmark (default Space) | 2 taps | High | N/A (goes straight into Anytype cloud sync) | No |
| Tasker → HTTP Request action | 2-3 taps | High | Tasker can queue | Yes (webhook) |
| Termux + `termux-share` + shell script | 4+ taps | Medium | Manual | Yes |
| KDE Connect "Send URL" → desktop handler | 2 taps | Medium (needs both online, same LAN) | No | Trivial (desktop handler) |
| Installed PWA with `share_target` | 2-3 taps | Medium (Chromium-only, service worker required) | Limited | Yes (PWA + server) |
| Telegram "Saved Messages" → bot poller | 2 taps | High | Full — Telegram buffers | Yes (bot) |
| Email share → IMAP poller | 3+ taps | Medium | Full — mail queue | Yes (IMAP poller) |

Notes:

- **HTTP Shortcuts** ([http-shortcuts.rmy.ch](https://http-shortcuts.rmy.ch/),
  MIT, [github.com/Waboodoo/HTTP-Shortcuts](https://github.com/Waboodoo/HTTP-Shortcuts)): supports
  GET/POST/etc., variable injection, JS pre/post-processing, bearer auth. Docs excerpts don't
  spell out "share target" explicitly but the app is widely used exactly this way — a shortcut can
  be triggered from the Android sharesheet and receives shared text/URL as an injectable variable.
  **Verify this with a smoke test before committing** (the docs are thin here).
- **Anytype's own Android share sheet** works today and creates a Bookmark object in your default
  Space, but there is a live enhancement request
  ([anytype-kotlin#2711](https://github.com/anyproto/anytype-kotlin/issues/2711)) asking for
  "choose Space / Collection / type on share." Until that ships, using Anytype's native share
  means every save lands in the default Space's inbox and requires manual filing. Fine if you're
  happy running a daily "file Instagram bookmarks" ritual; not fine if you want automation.
- **PWA `share_target`** ([MDN reference](https://developer.mozilla.org/en-US/docs/Web/Manifest/share_target),
  [W3C spec](https://w3c.github.io/web-share-target/), [Chrome capabilities doc](https://developer.chrome.com/docs/capabilities/web-apis/web-share-target)):
  the PWA has to be *installed* (`A2HS`), Chromium-only on Android in practice, and on Android a
  shared Instagram URL arrives in the `text` param — the browser opportunistically promotes it to
  `url` if it parses. Works, but the install+SW dance is heavy for a personal tool.
- **KDE Connect** is attractive on Linux but requires the desktop to be awake and paired.
  Fine as a redundancy channel, not as the primary.

### 3.2 iOS

- **Shortcuts.app** with a "Get URLs from Input" → "Get Contents of URL" (POST) action is the
  direct equivalent of HTTP Shortcuts. Same reliability, same 3-tap flow.
- No native Anytype share extension on iOS at time of writing beyond the same basic
  "Add to Anytype" path as Android.

### 3.3 Recommendation for share flow

- **Primary:** Android → **HTTP Shortcuts** share target → `POST /ingest` on a tiny Go/Python
  service you run somewhere the phone can reach (LAN box, Tailscale-exposed desktop, or a $5 VPS).
  That service writes to a **durable queue** (SQLite table is enough) and a worker drains the
  queue to the local Anytype API when the desktop is up.
- **Fallback / offline burst tolerance:** Telegram bot as an alternate intake. Share to a private
  Telegram chat with a bot; the bot appends to the same queue. Telegram absorbs offline periods
  and cross-device.
- **Do not** rely on Anytype's own share sheet as the primary path until
  [anytype-kotlin#2711](https://github.com/anyproto/anytype-kotlin/issues/2711) ships Collection
  selection — otherwise every capture requires manual filing.

---

## 4. Prior art / adjacent tools worth stealing ideas from

- **Karakeep** (formerly Hoarder) — [`karakeep-app/karakeep`](https://github.com/karakeep-app/karakeep),
  [docs.karakeep.app](https://docs.karakeep.app/). Self-hosted bookmark-everything app. Has iOS
  and Android apps and a REST API. **No Anytype integration.** No dedicated Instagram ingest.
  Steal from it: (a) the "AI auto-tag on ingest" pattern, (b) the "install as PWA share target"
  fallback, (c) its background-fetch/enrichment worker architecture.
- **Linkding** — has a community MCP server
  ([`chickenzord/linkding-mcp`](https://github.com/chickenzord/linkding-mcp)). Simple REST,
  browser extension, no Anytype bridge, no Instagram.
- **LinkAce, Wallabag, Shiori** — general-purpose self-hosted bookmark/read-later apps. None
  speak Anytype, none ingest Instagram specifically. Wallabag's fetch pipeline (readability +
  archive) is worth cribbing if you want captions/comments enrichment.
- **Anytype MCP** ([`anyproto/anytype-mcp`](https://github.com/anyproto/anytype-mcp), official
  MIT) — the right bridge if you want an agent (Claude Code, etc.) to *manage* the ingested
  Collection later. Not the right thing for the ingest hot path.
- **Homepage / Homarr / Dashy** — dashboards; no native Anytype bridge.

Net: nobody has built this specific pipeline. The building blocks all exist independently.

---

## 5. Synthesis + recommended architecture

### 5.1 Two-part recommended architecture

**Backfill path (one-shot):**

1. Request DYI (`Saved` only, JSON, all time).
2. Wait, download the ZIP within 4 days.
3. Parse `saved_posts.json` (and per-collection files) into `{url, saved_at, collection?}`.
4. Local Python script → `POST /v1/spaces/{id}/objects` with `type_key=bookmark` per link, then
   `POST /v1/spaces/{id}/lists/{list_id}/objects` to file into the Collection.
5. Persist an `ingested_urls.sqlite` for dedup.

**Ongoing share path:**

- Android **HTTP Shortcuts** shortcut registered as share target. Shares to Instagram-URL → the
  shortcut POSTs `{url, source: "share", ts}` to `https://ingest.<your-host>/instagram`.
- Tiny **ingest service** (Go or Python, ~200 LOC): auth by bearer token, validates URL, writes
  row to `queue.sqlite`. Returns 202 immediately.
- **Worker** on the desktop (systemd user unit) polls the queue every 30s; when the desktop
  Anytype process is up, drains → dedup against sqlite → create Bookmark → add to Collection.
- Optional: nightly `instaloader :saved` sweep as belt-and-braces to catch anything the share
  flow missed.

### 5.2 Biggest risk

**Instagram ToS + auth durability**, in that order.

- The DYI path is legally clean but slow and manual.
- Any automation on top of `instaloader :saved` violates Instagram's ToS in principle, and in
  practice can trigger a checkpoint / temporary lockout that requires manual intervention on the
  phone. This is the single failure mode most likely to break the pipeline unexpectedly.
- Anytype API stability is a distant second. It's versioned via `Anytype-Version` header and the
  team is shipping OpenAPI specs, so upgrades are manageable. But it *is* pre-1.0 in developer
  perception, and the exact `properties` shape for typed relations may change.

### 5.3 Alternate architectures

- **All-scraper (no DYI):** just run `instaloader :saved` on cron. Pro: single code path, catches
  new saves within poll interval. Con: highest ToS exposure, brittlest under checkpoint.
- **All-share (no scraper, no DYI):** treat existing saves as sunk cost, only bookmark going
  forward via the share sheet. Pro: legally impeccable, minimal moving parts. Con: no backfill —
  years of curation stay stranded in Instagram.
- **Bookmark manager in the middle** (e.g. Karakeep as the "hot" store, Anytype as the archive):
  share to Karakeep's Android app → Karakeep's API → nightly job re-emits into Anytype. Pro:
  Karakeep's mobile UX is already good; you get AI tagging free. Con: two systems of record; the
  "authoritative Collection" now has two owners.
- **Anytype-native only:** wait for [anytype-kotlin#2711](https://github.com/anyproto/anytype-kotlin/issues/2711)
  to land Collection selection in the Android share sheet, then use only Anytype. Pro: zero
  custom infrastructure. Con: unknown timeline; still no backfill story.

### 5.4 Open questions the user must decide

1. **Which Anytype Space?** Personal vault or a dedicated "Curation" Space. Affects the
   `space_id` hard-coded in the worker.
2. **Anytype network mode?** Anytype's cloud sync ("Any Sync") vs. self-hosted network vs. local-
   only. All three work with the local API identically, but self-hosted vs. cloud changes where
   the mobile device sees the data.
3. **Where does the ingest service live?** LAN-only box + Tailscale (simplest, most private) vs.
   public VPS with bearer auth (works everywhere, more exposure). Cloud vs. LAN affects share-
   shortcut config on the phone.
4. **Do you want media archived?** DYI + Anytype fetch give link + OG-preview. If you want the
   actual reel/photo saved, `instaloader` per-URL is required and storage grows quickly. Default:
   no.
5. **Collection granularity.** One "Instagram Saved" Collection, or mirror Instagram's user-
   defined Collections as separate Anytype Collections? DYI includes the collection metadata; the
   ingest worker can either flatten or preserve.
6. **Dedup key.** Instagram shortcode? Full URL? Normalize `?igsh=...` tracking params before
   hashing.
7. **Session/2FA strategy for the periodic `instaloader` sweep.** Store the session file on the
   desktop, re-auth manually on checkpoint. Accept that this can fail silently.

---

## Sources (primary)

Anytype:
- [Anytype Developer Portal](https://developers.anytype.io/)
- [API Reference index (2025-11-08)](https://developers.anytype.io/docs/reference)
- [Authentication guide](https://developers.anytype.io/docs/guides/get-started/authentication)
- [Create Object reference (2025-03-17)](https://developers.anytype.io/docs/reference/2025-03-17/create-object/)
- [OpenAPI 2025-11-08 (raw)](https://raw.githubusercontent.com/anyproto/anytype-api/main/docs/reference/openapi-2025-11-08.yaml)
- [Local API feature doc](https://doc.anytype.io/anytype/features/integrations/local-api.md)
- [Collections doc](https://doc.anytype.io/anytype-docs/getting-started/sets/collections)
- [Bookmarks doc](https://doc.anytype.io/anytype/create/bookmarks)
- [`anyproto/anytype-heart`](https://github.com/anyproto/anytype-heart) — repo & service.proto
- [`anyproto/anytype-api`](https://github.com/anyproto/anytype-api) — docs repo
- [`anyproto/anytype-mcp`](https://github.com/anyproto/anytype-mcp) — official MCP
- [`anyproto/anytype-cli`](https://github.com/anyproto/anytype-cli)
- [anytype-kotlin#2711 (Android share sheet enhancement)](https://github.com/anyproto/anytype-kotlin/issues/2711)

Instagram:
- [PIRG "How to request and download Instagram data" walkthrough](https://pirg.org/resources/how-to-request-and-download-instagram-data/)
- [Instagram Help — Download your information](https://help.instagram.com/181231772500920)
- [Instaloader site + release info](https://instaloader.github.io/)
- [Instaloader troubleshooting (2FA, rate limits)](https://instaloader.github.io/troubleshooting.html)
- [`instaloader/instaloader`](https://github.com/instaloader/instaloader)
- [Apify "Saved Posts export" issue confirming absence](https://apify.com/apify/instagram-scraper/issues/saved-posts-export-2YaUwNWBleL3mlKis)
- [Instagram Graph API overview (2026 dev guide)](https://elfsight.com/blog/instagram-graph-api-complete-developer-guide-for-2026/)

Share flow:
- [HTTP Shortcuts (site)](https://http-shortcuts.rmy.ch/)
- [`Waboodoo/HTTP-Shortcuts`](https://github.com/Waboodoo/HTTP-Shortcuts)
- [MDN Web Share Target](https://developer.mozilla.org/en-US/docs/Web/Manifest/share_target)
- [W3C Web Share Target spec](https://w3c.github.io/web-share-target/)
- [Chrome Web Share Target capabilities](https://developer.chrome.com/docs/capabilities/web-apis/web-share-target)
- [Android ACTION_SEND / receive-simple-data](https://developer.android.com/training/sharing/receive)

Prior art:
- [Karakeep docs](https://docs.karakeep.app/) / [`karakeep-app/karakeep`](https://github.com/karakeep-app/karakeep)
- [`chickenzord/linkding-mcp`](https://github.com/chickenzord/linkding-mcp)
