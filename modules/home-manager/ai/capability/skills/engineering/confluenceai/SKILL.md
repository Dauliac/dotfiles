---
name: confluenceai
description: Cookbook for the Confluence Cloud REST v2 API against ${SITE} — auth (shares the Jira token as break-glass; `twg` OAuth is the primary path), URL / tiny-link / bare-reference parsing, page-by-id vs page-by-title fetches, body-format tradeoffs (storage vs atlas_doc_format vs view + HTML→text), first-level children walk, ancestors, CQL search (v1 endpoint), inline / footer comments, and `twg confluence content get` as the preferred single-page read. Trigger on any Confluence read — "confluence page", "confluence doc", "atlassian doc", "the atlassian doc", "atlassian.net/wiki", "wiki/spaces/", "wiki/x/" (tiny link), "runbook link", "the runbook", "search confluence", "CQL", "how do I read a confluence page", or when a message contains a `<tenant>.atlassian.net/wiki/...` URL or a bare `<SPACE_KEY>/<pageId>` reference (e.g. `ARCHI/3945037839`, `PUL/3160310321`). Every companion `confluence-*` skill loads this on first invocation. Not for authoring / editing pages (out of scope for now). For semantic Rovo search, cross-product discovery, or when the anchor is not a specific Confluence page (person, project, goal, work item, repo, topic), prefer the `twg` skill instead — this cookbook is for direct v2/v1 REST reads of a known page or CQL-scoped title search when twg does not fit.
---

# confluenceai — Confluence Cloud REST v2 cookbook

Read this FIRST when about to hit the Confluence API. Shares auth,
placeholders, and config source-of-truth with the sibling `jiraai`
skill — do not duplicate the token, do not hard-code the site.

## Placeholder legend — same source as `jiraai`

Every `${VAR}` below is a placeholder. Real values live in
`~/.local/share/jiraai/config.yaml` (managed by home-manager).

| Placeholder | What it is | Yaml key |
| --- | --- | --- |
| `${SITE}` | Atlassian tenant hostname | `site` (e.g. `mycorp.atlassian.net`) |
| `${USER_EMAIL}` | operator's Atlassian email | `user.email` |

**Bootstrap block** every recipe assumes ran first:

```bash
CFG=~/.local/share/jiraai/config.yaml
: "${SITE:=$(yq -r '.site' "$CFG")}"
: "${USER_EMAIL:=$(yq -r '.user.email' "$CFG")}"
TOKEN=$(cat ~/.config/sops-nix/secrets/atlassian_api_token)
AUTH="$USER_EMAIL:$TOKEN"
V2="https://$SITE/wiki/api/v2"       # v2 — pages, children, ancestors, comments
V1="https://$SITE/wiki/rest/api"     # v1 — CQL search, tiny-link expand
```

## Auth

Shares one API token with Jira. Same file: `~/.config/sops-nix/secrets/atlassian_api_token`
(mode 0400, sops-managed). Same HTTP Basic scheme (`email:token`). No
separate Confluence credential — do NOT invent one.

## API selection — v2 for reads, v1 for search / tiny-links

Atlassian split the Confluence Cloud API in half in 2024:

| Task | Endpoint | Why |
| --- | --- | --- |
| Fetch a page by ID | `GET $V2/pages/{id}` | v2 is the read-of-record; supports `body-format` |
| Fetch by title | `GET $V2/pages?space-id={sid}&title=<t>` | v2 requires `space-id`, not `space-key` |
| Space key → space id (once, cache it) | `GET $V2/spaces?keys=ARCHI` | v2 pages endpoints only take numeric ids |
| Direct children | `GET $V2/pages/{id}/children` | one level down |
| All descendants | `GET $V2/pages/{id}/descendants` | tree — expensive, gate behind operator OK |
| Ancestors | `GET $V2/pages/{id}/ancestors` | breadcrumb / space location |
| Inline comments | `GET $V2/pages/{id}/inline-comments` | reviewer annotations |
| Footer comments | `GET $V2/pages/{id}/footer-comments` | thread at bottom of page |
| **CQL search** | `GET $V1/search?cql=<q>` | **v2 has no CQL yet — must use v1** |
| Expand tiny link `wiki/x/<code>` | `GET $V1/content?tinyLink=<code>` | v1 only |

Rule of thumb: default to `$V2`; drop back to `$V1` only when the
functionality isn't in v2 (search, tiny-links, some legacy expansions).

## Parsing an Atlassian URL / reference

Users paste Confluence pointers in ≥5 shapes. Handle them all:

| Shape | Example | Extract |
| --- | --- | --- |
| Full URL | `https://${SITE}/wiki/spaces/ARCHI/pages/3945037839/Delete+a+subgraph` | id `3945037839`, space `ARCHI`, slug (ignore) |
| Full URL, no slug | `https://${SITE}/wiki/spaces/PUL/pages/3160310321` | id `3160310321`, space `PUL` |
| Old viewpage | `https://${SITE}/wiki/pages/viewpage.action?pageId=123` | id `123` |
| Tiny link | `https://${SITE}/wiki/x/AbCdEf` | tiny code `AbCdEf` — expand via v1 (see below) |
| Bare space/id reference (informal) | `ARCHI/3945037839`, `PUL/3160310321` | id + space, no URL |
| Title-only reference | `"the Delete a subgraph runbook"` | search via CQL, ranked by `lastmodified DESC` |

**Extractor** — bash regex, no jq needed (input on stdin or `$1`):

```bash
extract_confluence_ids() {
  # Emits one `id[<TAB>space]` per line. Empty output = no matches.
  local text="${1:-$(cat)}"
  # /wiki/spaces/<SPACE>/pages/<ID>
  echo "$text" | grep -oE '/wiki/spaces/[A-Z0-9]+/pages/[0-9]+' \
    | awk -F/ '{print $6"\t"$4}'
  # /pages/viewpage.action?pageId=<ID>
  echo "$text" | grep -oE 'pageId=[0-9]+' | awk -F= '{print $2}'
  # Bare "<SPACE>/<numeric-id>" — 6+ digits to avoid false positives on jira keys
  echo "$text" | grep -oE '\b[A-Z][A-Z0-9]{1,15}/[0-9]{6,}\b' \
    | awk -F/ '{print $2"\t"$1}'
}

# Tiny links need an API call — emit them separately for `expand_tiny_link` below.
extract_tiny_links() {
  grep -oE '/wiki/x/[A-Za-z0-9]+' | awk -F/ '{print $4}'
}
```

**Tiny-link expansion** (v1):

```bash
expand_tiny_link() {
  local code=$1
  curl -sS -u "$AUTH" "$V1/content?tinyLink=$code&expand=" \
    | jq -r '.results[0].id'
}
```

## Fetch a page — pick the right body format

`body-format` values (v2):

| Value | Shape | Use it when |
| --- | --- | --- |
| `storage` | Confluence XHTML source | You want structure (tables, macros) preserved |
| `atlas_doc_format` | ADF JSON | You want to reason on structured content programmatically |
| `view` | rendered HTML | You want human-readable text (pipe to `pandoc` / `w3m -dump`) |

**Read-a-page recipe** (default: rendered → text, streams to stdout):

```bash
read_page() {
  local id=$1
  local page
  page=$(curl -sS -u "$AUTH" \
    "$V2/pages/$id?body-format=view&include-labels=true&include-version=true")
  local title space_id updated
  title=$(echo "$page"    | jq -r '.title')
  space_id=$(echo "$page" | jq -r '.spaceId')
  updated=$(echo "$page"  | jq -r '.version.createdAt')

  echo "===== $id ====="
  echo "title: $title"
  echo "space_id: $space_id  updated: $updated"
  echo
  echo "$page" | jq -r '.body.view.value' \
    | pandoc -f html -t plain --wrap=none 2>/dev/null \
      || echo "$page" | jq -r '.body.view.value' | w3m -dump -T text/html
}
```

Pandoc gives clean text; `w3m` is the fallback. If neither is installed,
last resort: `jq -r '.body.view.value' | sed 's/<[^>]*>//g'` (loses lists).

**Read by title** (needs space id first — v2 does not accept space keys):

```bash
title_to_id() {
  local space_key=$1 title=$2
  local sid
  sid=$(curl -sS -u "$AUTH" "$V2/spaces?keys=$space_key" | jq -r '.results[0].id')
  curl -sS -u "$AUTH" --data-urlencode "title=$title" -G \
    "$V2/pages?space-id=$sid&limit=1" | jq -r '.results[0].id'
}
```

## First-level children walk

The user's stated need: fetch the mentioned page **and** its direct
children (one level). Do NOT walk descendants without an operator OK —
a big page tree is 100+ API calls.

```bash
list_children() {
  local id=$1
  # Paginated — `_links.next` is a relative path; join with $V2 base host.
  curl -sS -u "$AUTH" "$V2/pages/$id/children?limit=100" \
    | jq -r '.results[] | [.id, .title] | @tsv'
}

read_page_and_children() {
  local id=$1
  read_page "$id"
  echo
  echo "--- first-level children of $id ---"
  list_children "$id" | while IFS=$'\t' read -r cid ctitle; do
    echo
    echo ">>> child: $ctitle ($cid)"
    read_page "$cid"
  done
}
```

**Cost sanity check** first — abort the fan-out if there are too many
children:

```bash
n=$(list_children "$id" | wc -l)
if [ "$n" -gt 15 ]; then
  echo "WARN: $id has $n direct children — ask operator before fetching all"
  exit 2
fi
```

## Ancestors — where is this page in the space?

Useful for context ("this runbook lives under Platform / GraphQL /
Delete flows"):

```bash
curl -sS -u "$AUTH" "$V2/pages/$id/ancestors" \
  | jq -r '.results[] | [.id, .title] | @tsv'
```

## CQL search — v1, when there is no explicit page

CQL = Confluence Query Language. Full grammar:
<https://developer.atlassian.com/server/confluence/advanced-searching-using-cql/>.

```bash
# Title + space + freshness — the 95% case
q='space = ARCHI AND type = page AND title ~ "Delete subgraph" ORDER BY lastmodified DESC'
curl -sS -u "$AUTH" -G --data-urlencode "cql=$q" --data 'limit=10' \
  "$V1/search" \
  | jq -r '.results[] | [.content.id, .content.type, .lastModified, .title] | @tsv'
```

Common CQL patterns:

| Intent | CQL |
| --- | --- |
| Fresh + relevant | `type = page AND text ~ "\"graphql router\"" ORDER BY lastmodified DESC` |
| Restrict to a space | `space = ARCHI AND text ~ "..."` |
| Label filter | `label = runbook AND text ~ "..."` |
| Recently updated only | `type = page AND lastmodified > "2026-01-01"` |
| Exact-phrase | `text ~ "\"delete a subgraph\""` (double-quote the phrase inside CQL) |

**Trap**: CQL `~` = "matches" (tokenized), `=` = "exact". For freeform
search, always `~`. For a known label / space / type, use `=`.

**Trap**: `.results[].content.id` is a **string**, all other v2 endpoints
also treat it as a string. Do not `tonumber` — leading-zero collisions
are theoretical but the API is stringly-typed.

## Comments

```bash
# Footer comments (thread at the bottom)
curl -sS -u "$AUTH" "$V2/pages/$id/footer-comments?body-format=view&limit=100" \
  | jq -r '.results[] | [.version.createdAt, .version.authorId, .body.view.value] | @tsv'

# Inline (reviewer annotations tied to a text selection)
curl -sS -u "$AUTH" "$V2/pages/$id/inline-comments?body-format=view&limit=100" \
  | jq -r '.results[] | {created: .version.createdAt, resolved: .resolutionStatus, text: .body.view.value}'
```

## `twg confluence content get` — when to use it over curl

`twg` covers the single-page read case (and much more — space search,
hierarchy walks, comment/version fan-out). It authenticates through the
shared twg OAuth session (`twg env`), so no bootstrap block needed.

```bash
twg confluence content get --id 3945037839 --body-format view -o json | jq -r '.body.view.value'
twg confluence content get --id 3945037839 --include-labels --include-version -o json
twg confluence tree --id 3945037839 --depth 1     # direct children
```

See the `twg-confluence` skill for the full surface (CQL via
`confluence search query --cql`, ancestors, attachments, editing, exports).

**Use curl (this cookbook)** when: (a) twg OAuth is unavailable and the
sops-managed `atlassian_api_token` is the only auth path, (b) you need
a raw v1/v2 endpoint twg does not surface (tiny-link expansion is the
canonical example), or (c) you need to reason on the raw JSON shape
for a pipeline. For everything else prefer `twg confluence …`.

## Batch fetch — N ids in one loop

There is no batch page endpoint in v2. Loop, but cap the fan-out
(mirrors the `remoteLinks` rule in `jiraai`):

```bash
ids=(3945037839 3160310321 3847946319)
if [ "${#ids[@]}" -gt 10 ]; then
  echo "WARN: ${#ids[@]} pages — ask operator before fetching all"; exit 2
fi
for id in "${ids[@]}"; do read_page "$id"; echo; done
```

## Common failure modes (grep-worthy)

| Symptom | Cause | Fix |
| --- | --- | --- |
| `401 Unauthorized` | Wrong auth pair — Basic with `email:token`, not just token | Re-check `$AUTH` (`echo "${AUTH%%:*}"` should print your email) |
| `404 Not Found` on `$V2/pages/<id>` | Page is a draft, or archived, or wrong id | Add `?status=current,archived,draft`, or re-check id from the URL |
| `body.view.value` is empty | Requested `body-format=storage` then piped to pandoc as HTML | Storage is XHTML with `ac:*` macros — pandoc `-f html` half-works. Use `view` for text extraction. |
| CQL returns `.results = []` for a title you can see in browser | Title contains punctuation not tokenized by CQL | Search by `text ~ "\"phrase\""` instead of `title ~` |
| `space-key` parameter ignored in v2 | v2 uses `space-id` (numeric), not `space-key` | Resolve key → id via `$V2/spaces?keys=<KEY>` (see `title_to_id`) |
| Tiny link `wiki/x/<code>` → 404 with v2 | v2 has no tiny-link endpoint | Use v1: `$V1/content?tinyLink=<code>` |

## Composes with

- **`confluence-auto-read`** — the trigger: extracts Confluence
  references from any incoming text (Dust reply, MR body, Slack, Jira
  ticket, prompt) and calls the recipes above. Loads this cookbook
  first.
- **`jiraai`** — shares the API token + `${SITE}` placeholder. If a
  Jira ticket description mentions a Confluence URL, `jiraai-review`
  should hand off to `confluence-auto-read`.
- **`dust`** — Dust cites Confluence pages by URL in `agentAnswer`.
  After every Dust reply, run `extract_confluence_ids` on the answer
  and read the sources yourself — do not trust the summary verbatim
  (the citation is a claim, not a read).
