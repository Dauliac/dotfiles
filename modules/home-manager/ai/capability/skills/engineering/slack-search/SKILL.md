---
name: slack-search
description: Full-text search across a Slack workspace via `slack api search.messages` — the same search bar as the Slack UI, driven from the CLI. Supports the full search-modifier grammar (`from:`, `in:`, `has:`, `before:`, `after:`, `during:`), pagination, and sort by score / timestamp. Trigger on: "search slack for X", "find slack messages about", "who said X in slack", "search #foo for term", "slack messages from @user last week", "look up 'error 500' across slack", or when a targeted `conversations.history` scan would be too slow. Requires a USER token (search.* is not available to bots); the `slack login` session covers this.
---

# slack-search — text search across the workspace

Slack Web API method: [`search.messages`](https://docs.slack.dev/reference/methods/search.messages).
Sibling: `search.files` (same grammar, indexes file attachments).

## Only user tokens

`search.*` refuses bot tokens. The `slack login` session is a user
token, so this works out of the box. If `SLACK_BOT_TOKEN` is exported
and preempting, override with `--token "$SLACK_USER_TOKEN"` or
`unset SLACK_BOT_TOKEN`.

## Basic query

```bash
slack api search.messages query="deploy failed"
```

Response: `messages.matches: [{ts, channel, user, text, permalink, …}]`
+ paging metadata under `messages.paging`.

## Search grammar

Same modifiers as the Slack UI:

| Modifier | Example | Meaning |
| --- | --- | --- |
| `from:` | `from:@juliend` | Author (name or ID) |
| `in:` | `in:#platform` | Channel |
| `to:` | `to:@juliend` | DMs sent to a user |
| `has:` | `has:link`, `has:pin`, `has:reaction`, `has:file` | Message contents |
| `before:` `after:` `during:` `on:` | `after:2026-01-01`, `during:january` | Time bounds |
| `is:` | `is:thread`, `is:starred`, `is:saved` | Message state |

Combine freely — quote the whole thing:

```bash
slack api search.messages \
  query='from:@juliend in:#platform "database migration" after:2026-01-01'
```

## Sort + pagination

```bash
slack api search.messages \
  query="canary" \
  sort=timestamp sort_dir=desc \
  count=100 page=1
```

- `sort=score` (default, best-match) or `sort=timestamp`.
- `sort_dir=asc|desc`.
- Paginate with `page=N` (1-indexed) or the `cursor` returned in
  `response_metadata.next_cursor` on newer accounts.
- `count` = page size, max 100.

## Grep-friendly output

```bash
slack api search.messages query='error 500' count=50 \
  | jq -r '.messages.matches[] |
      "\(.ts | tonumber | strftime("%Y-%m-%d %H:%M"))  \(.channel.name)  \(.username // .user)  \(.permalink)"'
```

## Rate limits

Tier 3 (~50/min). Slack throttles heavier searches — check
`Retry-After` (`slack -i api …`) on 429.

## Common errors

| Error | Fix |
| --- | --- |
| `not_allowed_token_type` | You're using a bot token. Use the user session (`slack login`) or `--token "$SLACK_USER_TOKEN"`. |
| `missing_scope` | Needs `search:read`. Re-login and grant it. |
| Empty `messages.matches` on obvious hits | The user account isn't a member of the channel — Slack search only returns results the user could otherwise see. |
