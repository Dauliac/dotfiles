---
name: confluence-auto-read
description: Always-on policy for reading Atlassian / Confluence documentation the operator (or another agent) references. Trigger the moment ANY of these appear in the current turn — the user prompt, a Dust `agentAnswer`, a Jira ticket body, a GitLab MR description, a Slack paste, or any tool output — (a) a URL matching `atlassian.net/wiki/spaces/<KEY>/pages/<ID>` or `atlassian.net/wiki/x/<code>` or `atlassian.net/wiki/pages/viewpage.action?pageId=`, (b) a bare `<SPACE_KEY>/<pageId>` reference like `ARCHI/3945037839` or `PUL/3160310321`, (c) the literal phrases "atlassian doc", "the atlassian doc", "confluence doc", "confluence page", "the runbook", "the wiki page", "the doc", "the page" when the surrounding context names Confluence or Atlassian. Also trigger on vague mentions ("check the runbook", "there is a confluence about X") — fall back to CQL search. This skill delegates every actual API call to `confluenceai`; its own value is the *when* + *how far* policy, not the API surface. Do not use for editing pages.
---

# confluence-auto-read — auto-fetch Confluence sources on mention

Purpose: close the "I only relayed the Dust summary" gap. If a
Confluence page is referenced anywhere in the conversation, read it
yourself before reasoning on top of it. Summaries drift; citations are
stale; runbook URLs are 2022 dead links. **The doc is the ground
truth.**

## Loads

Every trigger of this skill loads **`confluenceai`** first — it owns
the auth, URL parser, `read_page`, `list_children`, and CQL recipes.
Do not reinvent them here.

## Trigger scan — run on every incoming text

Sources to scan:

1. The user's most recent prompt.
2. Any Dust `agentAnswer` you just received.
3. Any Jira issue body / comment you just fetched.
4. Any GitLab MR description / comment you just fetched.
5. Any Slack message / paste in the prompt.
6. Any tool output that contains user-authored text (runbook
   references, incident write-ups).

Scan pattern (from `confluenceai`):

```bash
extract_confluence_ids <<< "$SOURCE_TEXT"     # emits: id [\t space]
extract_tiny_links      <<< "$SOURCE_TEXT"    # emits: tiny code (needs expand)
```

If both extractors emit nothing but the source names Confluence / a
runbook / a doc without a URL — fall through to the **vague-mention
branch** below.

## Action policy — what to fetch, how far

| Signal | Action |
| --- | --- |
| 1 explicit page id / URL | `read_page` on it + `list_children` (one level, capped at 15 — see below) |
| Multiple explicit ids (≤10) | `read_page` on each (no children walk — too expensive) |
| Multiple explicit ids (>10) | Report the count, ask the operator which to prioritise, do NOT fetch all |
| Tiny link only | `expand_tiny_link` → then treat the resolved id as "1 explicit page" |
| Vague mention only | CQL search (see below) — offer the top 3 results, ask which to read |
| Bare `<SPACE>/<id>` reference | Same as explicit URL |

**Children walk cap**: 15 direct children max, per `confluenceai`'s
`list_children` sanity check. Above 15, report the count and ask.

**Never walk descendants** (`$V2/pages/{id}/descendants`) without a
direct operator instruction. That endpoint returns the whole subtree
and can be hundreds of pages.

## Vague-mention branch — CQL fallback

Triggers: "check the runbook", "the atlassian doc about X", "there's a
confluence on Y", "see the wiki page for Z" — no URL, no id.

1. Extract the topic keywords from the surrounding sentence (e.g.
   *"the runbook for deleting a subgraph"* → `delete subgraph`).
2. If the source names a space (e.g. *"in ARCHI"*, *"the PUL
   runbook"*), scope the CQL to it.
3. Run:

   ```bash
   q='type = page AND text ~ "\"<keywords>\"" ORDER BY lastmodified DESC'
   # + AND space = <KEY> if known
   curl -sS -u "$AUTH" -G --data-urlencode "cql=$q" --data 'limit=5' \
     "$V1/search" \
     | jq -r '.results[] | [.content.id, .lastModified, .title, .url] | @tsv'
   ```

4. Print the top 5 to the operator with `id | last-modified | title |
   url`, then ask which one(s) to read. Do not auto-read search
   results — the operator disambiguates.

## Freshness gate — before you cite a page as authoritative

Runbooks rot. A 2022 doc is a lie in 2026 more often than not.

Every fetched page in `read_page` gives you
`.version.createdAt`. Compare:

```bash
age_days=$(( ( $(date +%s) - $(date -d "$updated" +%s) ) / 86400 ))
if [ "$age_days" -gt 365 ]; then
  echo "WARN: page $id last updated $updated ($age_days days ago) — verify against a fresher source or a subject-matter expert before acting on it."
fi
```

Old page + high-stakes action (DELETE, migration, prod change) → do
NOT proceed on the doc alone; ask the operator or search for a newer
version by title.

## Trust order (when sources disagree)

1. The operator (they know what's current).
2. A Confluence page updated in the last 90 days.
3. Code / Nix / config in the current repo.
4. Any Dust reply.
5. An older Confluence page.
6. Anything you remember from training.

If (2) and (4) disagree, believe (2), and tell the operator Dust
summarized incorrectly.

## What NOT to auto-fetch

- **Jira ticket URLs** (`/browse/<KEY>`) — those are `jiraai` territory,
  not this skill. Leave them for `jiraai-review`.
- **Public Atlassian marketing / status pages** (`www.atlassian.com`,
  `status.atlassian.com`) — not Confluence Cloud, WebFetch them
  instead if needed.
- **Attachments** (`/download/attachments/…`) — usually large binaries;
  ask before downloading.
- **User profile URLs** (`/wiki/people/<accountId>`) — not documentation.
- **Whiteboards / databases** (`/wiki/spaces/*/whiteboards/*`,
  `/databases/*`) — v2 pages endpoints reject them (404). Report the
  URL to the operator and move on.

## Report format

After the scan + reads, before continuing with the task:

```
Confluence sources read for this turn:
- <id> "<title>" (updated <date>, <N> children) — key takeaway: <one line>
- <id> "<title>" (updated <date>) — key takeaway: <one line>

Discrepancies with the caller's summary (if any):
- <specifically what differed>
```

Keep the "key takeaway" one line — details go into the actual work,
not the report.

## Composes with

- **`confluenceai`** — every API call lives there.
- **`jiraai-review`** — after fetching a ticket body, run this skill's
  extractor on `.fields.description` (ADF) and `.fields.comment.comments[].body`.
- **`dust`** — after every Dust reply, run this skill's extractor on
  `.agentAnswer` and read the citations yourself. Dust's citation is
  a claim; the read is the truth.
- **`jira-explore`** / **`jira-fix`** — support-workflow steps that
  reference runbooks; this skill fires automatically when they surface
  a Confluence URL.
