---
name: slack-edit-message
description: Edit or delete a Slack message you posted, via `slack api chat.update` and `chat.delete`. Covers replacing text vs Block Kit blocks, deleting scheduled messages before they fire, the "you can only edit your own messages" rule, and the "edited" indicator Slack adds automatically. Trigger on: "edit that slack message", "update the message I posted", "fix a typo in slack", "delete that message", "remove slack message", "cancel scheduled slack message", or when a workflow needs to mutate a message referenced by `(channel, ts)`. Needs the `ts` returned by [[slack-send-message]].
---

# slack-edit-message — mutate a message you posted

Two methods:

- [`chat.update`](https://docs.slack.dev/reference/methods/chat.update)
- [`chat.delete`](https://docs.slack.dev/reference/methods/chat.delete)
- [`chat.deleteScheduledMessage`](https://docs.slack.dev/reference/methods/chat.deleteScheduledMessage) for scheduled messages before they fire

## Prerequisite

The `ts` of the message + the `channel` ID. Get `ts` from the
`chat.postMessage` response you saved earlier, from
[[slack-read-channel]], or from a permalink (see [[slack-send-message]]
for the permalink → ts conversion).

## Ownership rule

You can only edit / delete messages the current token posted (or a
workspace admin token, but that's out of scope for read/send). Trying
to edit someone else's message returns `cant_update_message` /
`cant_delete_message`.

## Update text

```bash
slack api chat.update \
  channel=C0123ABC \
  ts=1699999999.000000 \
  text="deploy completed :white_check_mark: (edited: v4.7.1)"
```

Slack automatically appends an "(edited)" marker in the UI.

## Update Block Kit blocks

Same rule as posting — use `--json`:

```bash
slack api chat.update --json '{
  "channel": "C0123ABC",
  "ts": "1699999999.000000",
  "text": "fallback",
  "blocks": [{"type":"section","text":{"type":"mrkdwn","text":"*new status:* :warning: rolled back"}}]
}'
```

Passing `blocks` alone will NOT clear existing blocks unless you also
send `blocks: []`. Same for `attachments`.

## Delete a live message

```bash
slack api chat.delete \
  channel=C0123ABC \
  ts=1699999999.000000
```

Irreversible. No confirmation prompt from Slack.

## Cancel a scheduled message

Scheduled messages have their own `scheduled_message_id` (returned by
`chat.scheduleMessage`) — NOT a `ts`:

```bash
slack api chat.deleteScheduledMessage \
  channel=C0123ABC \
  scheduled_message_id=Q0123ABCDEF
```

Only works BEFORE `post_at` fires; after that, use `chat.delete` on
the resulting `ts`.

## Common errors

| Error | Fix |
| --- | --- |
| `cant_update_message` / `cant_delete_message` | The token didn't post the message. |
| `message_not_found` | Bad `(channel, ts)`. Re-fetch from `conversations.history`. |
| `msg_too_long` | New text > 40 000 chars. Split. |
| `edit_window_closed` | Some workspaces disable edits after N minutes / hours (admin setting). |
