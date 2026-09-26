---
name: slack-read-channel
description: Read the message history of a Slack channel / DM / MPIM via `slack api conversations.history`. Covers cursor pagination, time-bounded fetches (`oldest` / `latest` Unix timestamps), and joining a public channel first when the token isn't a member. Trigger on: "read #channel", "what's in #foo lately", "last N messages from #bar", "history of the thread channel", "slack messages from yesterday in #x", "fetch dms with @user", "export channel messages". Does NOT fetch thread replies — use [[slack-thread]] for that. For full-text search across channels use [[slack-search]].
---

# slack-read-channel — read message history

Slack Web API method: [`conversations.history`](https://docs.slack.dev/reference/methods/conversations.history).

## Prerequisite

Channel ID (`C…`, `D…`, or `G…`). Resolve name → ID via
[[slack-list-channels]].

For public channels the user isn't a member of, join first:

```bash
slack api conversations.join channel=C0123ABC
```

Some workspaces disallow programmatic joins — in that case a human
must invite the token's user.

## Fetch recent messages

```bash
slack api conversations.history channel=C0123ABC limit=50
```

Returns `messages: [{ts, user, text, thread_ts?, reply_count?, …}]`
newest-first. `thread_ts == ts` marks a thread parent;
`thread_ts != ts` marks a thread reply flattened into history (rare
— thread replies normally live under `conversations.replies`).

## Time-bounded fetch

`oldest` and `latest` are Slack timestamps (Unix epoch seconds with
6-digit fraction: `1699999999.000000`). To fetch "since yesterday":

```bash
oldest=$(date -d 'yesterday 00:00' +%s).000000
slack api conversations.history channel=C0123ABC \
  oldest="$oldest" limit=200
```

`inclusive=true` includes messages exactly at `oldest` / `latest`.

## Full pagination

```bash
cursor=
while :; do
  page=$(slack api conversations.history channel=C0123ABC limit=200 cursor="$cursor")
  echo "$page" | jq -c '.messages[]'
  cursor=$(echo "$page" | jq -r '.response_metadata.next_cursor // empty')
  [ -z "$cursor" ] && break
done
```

`has_more: true` in the response also signals more pages.

## Prettify for humans

```bash
slack api conversations.history channel=C0123ABC limit=20 \
  | jq -r '.messages[] | "\(.ts | tonumber | strftime("%H:%M")) <\(.user // .bot_id)> \(.text)"'
```

User IDs (`U…`) show up raw — pair with a `users.info` lookup or a
one-shot `users.list` cache to display names ([[slack-list-users]]).

## Fetch a single message by ts

`conversations.history` with `latest=<ts>` and `inclusive=true`:

```bash
slack api conversations.history channel=C0123ABC \
  latest=1699999999.000000 inclusive=true limit=1
```

## Common errors

| Error | Fix |
| --- | --- |
| `channel_not_found` | Bad ID, or private channel the user isn't in. |
| `not_in_channel` | `conversations.join` for public; a human must invite for private. |
| `missing_scope` | Session needs `channels:history` / `groups:history` / `im:history` / `mpim:history`. Re-login with the right scopes. |
| `ratelimited` | Tier 3 (~50/min). Back off using `Retry-After` header (`slack -i api …`). |
