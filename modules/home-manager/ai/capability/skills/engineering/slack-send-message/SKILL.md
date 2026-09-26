---
name: slack-send-message
description: Post a message to a Slack channel, DM, or MPIM via `slack api chat.postMessage`. Covers plain text, mrkdwn, Block Kit blocks, DMs (channel = user ID), MPIMs (opening a group DM first), scheduled posts, and ephemeral messages (visible only to one user). Trigger on: "post to #channel", "send a slack message", "DM @user on slack", "message the team on slack", "notify #foo that …", "slack message to <user>", "post an ephemeral message to X", "schedule this slack message for …". For thread replies use [[slack-thread]]; for editing/deleting an existing message use [[slack-edit-message]]; for uploads use [[slack-upload-file]].
---

# slack-send-message — post a message

Slack Web API method: [`chat.postMessage`](https://docs.slack.dev/reference/methods/chat.postMessage).
Sibling methods covered here: `chat.postEphemeral`, `chat.scheduleMessage`.

## Prerequisite

Know the destination `channel` — a channel ID (`C…`), DM ID (`D…`),
MPIM ID (`G…`), or a user ID (`U…`) for a 1:1 DM. Resolve names to
IDs via [[slack-list-channels]] / [[slack-list-users]].

## Post to a channel

```bash
slack api chat.postMessage \
  channel=C0123ABC \
  text="deploy completed :tada:"
```

Response includes `ts` (message timestamp) and `channel` — save `ts`
if you may need to edit / delete / thread-reply later.

## DM a user

Slack auto-opens a DM when you post with `channel=<userID>`:

```bash
slack api chat.postMessage channel=U0123ABC text="ping"
```

## Group DM (MPIM)

Open first, then post:

```bash
mpim=$(slack api conversations.open users=U111,U222,U333 | jq -r '.channel.id')
slack api chat.postMessage channel="$mpim" text="huddle in 5"
```

## Rich content (Block Kit)

Use `--json` for anything with nested structure:

```bash
slack api chat.postMessage --json '{
  "channel": "C0123ABC",
  "text": "fallback for notifications",
  "blocks": [
    {"type":"header","text":{"type":"plain_text","text":"Deploy"}},
    {"type":"section","text":{"type":"mrkdwn","text":"*status:* :white_check_mark: green"}},
    {"type":"actions","elements":[
      {"type":"button","text":{"type":"plain_text","text":"View"},"url":"https://…"}
    ]}
  ]
}'
```

Always include `text` as a fallback — Slack uses it for notifications
+ accessibility when `blocks` is present.

## Post as a specific identity

- `username=…` + `icon_emoji=…` or `icon_url=…` — only honored with a
  bot token, and only if the app has `chat:write.customize`.
- `as_user=true` — deprecated; ignored on new apps.

## Ephemeral message (visible to one user)

```bash
slack api chat.postEphemeral \
  channel=C0123ABC \
  user=U0456DEF \
  text="you asked for this reminder"
```

Ephemeral messages disappear when the recipient reloads Slack — do
NOT use them for anything that must persist.

## Scheduled message

```bash
slack api chat.scheduleMessage \
  channel=C0123ABC \
  text="standup in 5min" \
  post_at=$(date -d '+5 min' +%s)
```

`post_at` is Unix epoch seconds. Cancel with
`chat.deleteScheduledMessage` before it fires.

## Common errors

| Error | Fix |
| --- | --- |
| `channel_not_found` | Bad ID, or the token's user is not a member. `conversations.join channel=…` first (public channels only). |
| `not_in_channel` | Bot user must be invited to the channel first. |
| `no_text` | Include `text=…` even when using `blocks`. |
| `msg_too_long` | Slack's 40 000-char / 50-block limit — split into multiple messages or attach a file. |
| `restricted_action` | Workspace guest / channel posting policy blocks non-members. |

## Post to a `slack.com` permalink

Given `https://mycorp.slack.com/archives/C0123ABC/p1699999999000000`:
- channel ID = `C0123ABC`
- ts = `1699999999.000000` (insert the `.` before the last 6 digits)
