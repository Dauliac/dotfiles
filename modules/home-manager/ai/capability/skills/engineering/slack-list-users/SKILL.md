---
name: slack-list-users
description: Resolve Slack user identity — name / email → ID and ID → profile — via `users.list`, `users.info`, and `users.lookupByEmail`. Covers filtering out bots and deactivated accounts, pagination, and the "cache to jq lookup" pattern for scripts that resolve many users. Trigger on: "user id for @juliend", "slack user for julien@…", "who is U0123ABC", "list slack users", "email → slack id", "resolve slack handle", or when a downstream skill ([[slack-send-message]] DM, [[slack-thread]], [[slack-react]]) needs a `U…` ID from a name / handle / email. For channels use [[slack-list-channels]].
---

# slack-list-users — resolve Slack user identity

Three methods, three shapes of question:

| Question | Method |
| --- | --- |
| Handle / display-name → `U…` | `users.list` + jq filter |
| Corp email → `U…` | `users.lookupByEmail` |
| `U…` → full profile (name, email, tz) | `users.info` |

## Email → ID (best when you have it)

```bash
slack api users.lookupByEmail email=user@example.com \
  | jq -r '.user.id'
```

Requires `users:read.email` scope. Fast, exact, one API call.

## Handle → ID

`users.list` returns everyone. Filter by `name` (handle) or
`profile.display_name`:

```bash
slack api users.list limit=1000 \
  | jq -r '.members[] |
      select(.name=="juliend" or .profile.display_name=="juliend") | .id'
```

## ID → profile

```bash
slack api users.info user=U0123ABC \
  | jq '.user | {id, name, real_name, email: .profile.email, tz}'
```

## Enumerate real humans only

Filter out bots + deactivated + Slackbot:

```bash
slack api users.list limit=1000 \
  | jq -r '.members[]
      | select(.deleted == false)
      | select(.is_bot == false)
      | select(.id != "USLACKBOT")
      | "\(.id)  @\(.name)  \(.profile.real_name)  \(.profile.email // "")"'
```

## Full pagination

```bash
cursor=
while :; do
  page=$(slack api users.list limit=1000 cursor="$cursor")
  echo "$page" | jq -c '.members[]'
  cursor=$(echo "$page" | jq -r '.response_metadata.next_cursor // empty')
  [ -z "$cursor" ] && break
done
```

## Cache once, look up many

`users.list` is Tier 2 (~20/min); large workspaces need pagination.
For scripts touching many users:

```bash
slack api users.list limit=1000 > /tmp/slack-users.json
# no API calls after this:
jq -r --arg h juliend \
  '.members[] | select(.name==$h) | .id' /tmp/slack-users.json
```

Refresh the cache on a schedule (e.g. daily) so new / renamed users
show up.

## Fields to know

- `id` — the `U…` you need for DM / mention / react targets.
- `name` — the handle (login), pre-@ (`juliend`, not `@juliend`).
- `profile.display_name` — the human-configurable display name.
- `profile.real_name` — legal / registered name.
- `profile.email` — needs `users:read.email` scope; absent otherwise.
- `is_bot`, `deleted`, `is_admin`, `tz`, `tz_offset` — filters.

## Common errors

| Error | Fix |
| --- | --- |
| `users_not_found` (lookupByEmail) | Email doesn't match a workspace member — check domain, alias, and whether the user is a multi-workspace guest. |
| `missing_scope` | `users:read` for list/info; `users:read.email` for the `.email` field + `lookupByEmail`. |
| `ratelimited` | Batch via the cache pattern above. |
