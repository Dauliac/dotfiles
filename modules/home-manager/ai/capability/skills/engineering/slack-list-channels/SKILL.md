---
name: slack-list-channels
description: Resolve Slack channel names → IDs (and enumerate channels the user can see) via `slack api conversations.list`. Covers filtering by type (`public_channel`, `private_channel`, `mpim`, `im`), including archived, pagination, and the "grep name → id" one-liner. Trigger on: "channel id for #foo", "list slack channels", "what channels am I in", "find the channel called X", "resolve slack channel name", or any time a downstream skill ([[slack-send-message]], [[slack-read-channel]]) needs a `C…` ID from a human-readable name. For user IDs use [[slack-list-users]].
---

# slack-list-channels — channels the user can see

Slack Web API method: [`conversations.list`](https://docs.slack.dev/reference/methods/conversations.list).

## Name → ID (the 90% case)

```bash
slack api conversations.list types=public_channel,private_channel limit=1000 \
  | jq -r '.channels[] | select(.name=="platform-alerts") | .id'
```

Prefix `#` is NOT part of the name field — `platform-alerts`, not
`#platform-alerts`.

## Enumerate visible channels

```bash
slack api conversations.list limit=200 \
  | jq -r '.channels[] | "\(.id)  \(.name)  members=\(.num_members)  archived=\(.is_archived)"'
```

## Filters

| Filter | Example | Notes |
| --- | --- | --- |
| `types` | `types=public_channel,private_channel,mpim,im` | Comma-list. `im` = DMs, `mpim` = group DMs. |
| `exclude_archived` | `exclude_archived=true` | Default `false`. |
| `limit` | `limit=1000` | Max 1000 per page. |
| `team_id` | `team_id=T0123` | Enterprise Grid — restrict to one workspace. |

## Full pagination

```bash
cursor=
while :; do
  page=$(slack api conversations.list limit=1000 cursor="$cursor" \
    types=public_channel,private_channel)
  echo "$page" | jq -c '.channels[]'
  cursor=$(echo "$page" | jq -r '.response_metadata.next_cursor // empty')
  [ -z "$cursor" ] && break
done
```

## Include DMs / group DMs

DMs surface only for the *token's* user:

```bash
slack api conversations.list types=im limit=200 \
  | jq -r '.channels[] | "\(.id)  user=\(.user)"'
```

Match the counterpart user via [[slack-list-users]].

## Metadata worth keeping

Per-channel: `id`, `name`, `is_private`, `is_archived`,
`is_member` (is the token's user in it), `num_members`, `topic.value`,
`purpose.value`, `created`.

## Cache to avoid re-listing

`conversations.list` is Tier 2 (~20/min). If a script needs the same
lookup repeatedly, dump once and grep:

```bash
slack api conversations.list types=public_channel,private_channel limit=1000 \
  > /tmp/slack-channels.json
# later, no API call:
jq -r '.channels[] | select(.name=="…") | .id' /tmp/slack-channels.json
```

## Common errors

| Error | Fix |
| --- | --- |
| `missing_scope` | Needs `channels:read` + `groups:read` (+ `im:read`, `mpim:read` for DM types). |
| `invalid_types` | Comma-separated with no spaces: `public_channel,private_channel`. |
| `ratelimited` | Back off using `Retry-After`. |
