---
name: slack-react
description: Add or remove an emoji reaction on a Slack message via `slack api reactions.add` / `reactions.remove`, and list existing reactions with `reactions.get`. Covers custom-emoji names (bare, no colons), the (channel + ts) identity a reaction targets, and the `already_reacted` idempotency. Trigger on: "react with :emoji: to", "add a reaction to that message", "thumbs-up that slack message", "remove my reaction", "who reacted to X", or when a workflow needs to acknowledge a message without posting a reply. Feeds off channel IDs from [[slack-list-channels]] and ts values from [[slack-read-channel]] / [[slack-search]].
---

# slack-react — add / remove message reactions

Slack Web API methods:

- [`reactions.add`](https://docs.slack.dev/reference/methods/reactions.add)
- [`reactions.remove`](https://docs.slack.dev/reference/methods/reactions.remove)
- [`reactions.get`](https://docs.slack.dev/reference/methods/reactions.get)

## Identity of a reaction

Every reaction is `(channel, ts, emoji-name, actor)`. The actor is
the token's user — you can only add / remove YOUR OWN reactions.

`ts` comes from a `chat.postMessage` response, from
`conversations.history` ([[slack-read-channel]]), from
`conversations.replies` ([[slack-thread]]), or from a `slack.com`
permalink (see [[slack-send-message]] for the permalink → ts recipe).

## Add a reaction

```bash
slack api reactions.add \
  channel=C0123ABC \
  timestamp=1699999999.000000 \
  name=white_check_mark
```

Emoji `name`: **bare, no colons.** `white_check_mark`, not
`:white_check_mark:`. Custom workspace emoji work with their exact
short name (`name=team-victory`).

## Remove a reaction

```bash
slack api reactions.remove \
  channel=C0123ABC \
  timestamp=1699999999.000000 \
  name=white_check_mark
```

Only removes YOUR reaction, not everyone else's.

## List reactions on a message

```bash
slack api reactions.get \
  channel=C0123ABC \
  timestamp=1699999999.000000 \
  full=true
```

Response `message.reactions: [{name, count, users:[U…]}]`. `full=true`
returns the full user list per reaction (otherwise truncated).

## Common errors

| Error | Fix |
| --- | --- |
| `no_reaction` (remove) | You never added this reaction — nothing to remove. Safe to ignore in idempotent scripts. |
| `already_reacted` (add) | You already added it. Safe to ignore in idempotent scripts. |
| `invalid_name` | Emoji doesn't exist in the workspace. Standard emoji list: <https://api.slack.com/methods/reactions.add#emoji_names>. |
| `message_not_found` | `channel` or `timestamp` doesn't identify a live message. |
| `missing_scope` | `reactions:write` for add/remove; `reactions:read` for get. |
