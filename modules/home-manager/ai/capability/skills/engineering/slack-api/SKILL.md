---
name: slack-api
description: Generic escape hatch for calling any Slack Web API method with `slack api <method>` when no atomic sub-skill covers it. Covers form-encoded vs JSON body, token priority, pagination via cursor, rate-limit handling (`Retry-After`), and verbose debugging. Trigger on: "slack api <method>", "call slack.<something>", "raw slack api", "which endpoint returns X", any Slack Web API method name (`chat.*`, `conversations.*`, `users.*`, `files.*`, `reactions.*`, `search.*`, `pins.*`, `bookmarks.*`, `views.*`, `usergroups.*`, `team.*`), or when a purpose-built slack-* skill exists but the user wants raw control. Prefer the purpose-built sub-skills for the top of [[slack]]'s map when they cover the operation.
---

# slack-api — the raw `slack api` escape hatch

Every messaging op is a `slack api <method>` call. This skill exists
for the long tail — pins, bookmarks, usergroups, team metadata,
admin methods — where no dedicated sub-skill exists yet.

## Payload shapes

```bash
# form-encoded — positional key=value
slack api chat.postMessage channel=C123 text="hi"

# JSON body — needed for nested payloads (blocks, attachments,
# metadata, filter objects)
slack api chat.postMessage --json '{
  "channel": "C123",
  "blocks": [{"type":"section","text":{"type":"mrkdwn","text":"*hi*"}}]
}'

# Raw form string
slack api chat.postMessage --data 'channel=C123&text=hi'

# GET override (some methods require GET)
slack api users.info user=U123 -X GET

# Extra headers
slack api chat.postMessage -H 'X-Foo: bar' channel=C123 text=hi
```

## Token priority

1. `--token <value>` — highest, use for one-off overrides.
2. `--app <id>` — install/select app for bot token (project-only).
3. `SLACK_BOT_TOKEN` env — bot token.
4. `SLACK_USER_TOKEN` env — user token.
5. Interactive prompt (in project dir with `slack.json`).

For read/send messages, the `slack login` session covers cases 4+5.

## Pagination

Methods that return lists (`conversations.list`,
`conversations.history`, `users.list`, `search.messages`) paginate
with cursors:

```bash
# First page
slack api conversations.list limit=200
# → response has response_metadata.next_cursor

# Next page
slack api conversations.list limit=200 cursor=dGVhbTpDMDYzR…

# All pages (bash loop)
cursor=
while :; do
  page=$(slack api conversations.list limit=200 cursor="$cursor")
  echo "$page" | jq -c '.channels[]'
  cursor=$(echo "$page" | jq -r '.response_metadata.next_cursor // empty')
  [ -z "$cursor" ] && break
done
```

## Rate limits

Slack returns HTTP 429 with `Retry-After: <seconds>` when throttled.
Use `-i` to see the header:

```bash
slack -i api chat.postMessage channel=C123 text=hi
```

Method tiers (Tier 1 slowest, Tier 4 fastest):
- Tier 1 (~1/min): `admin.*`
- Tier 2 (~20/min): `conversations.list`, `users.list`
- Tier 3 (~50/min): `conversations.history`, `search.messages`
- Tier 4 (~100/min): `chat.postMessage`, `reactions.add`

## Debug a failing call

```bash
slack -v api <method> …
```

`-v` dumps the full HTTP request + response — invaluable for
`missing_scope`, `channel_not_found`, or malformed-payload errors.

## Method discovery

- Full method reference: <https://docs.slack.dev/reference/methods>
- Search from CLI: `slack docs search "post message"`

## Parsing output

Every response is JSON with a top-level `ok: bool`. Always guard:

```bash
resp=$(slack api chat.postMessage channel=C123 text=hi)
echo "$resp" | jq -e '.ok' >/dev/null || {
  echo "$resp" | jq -r '.error // "unknown error"'
  exit 1
}
```
