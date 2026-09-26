---
name: slack-thread
description: Post a reply into a Slack thread (`chat.postMessage` + `thread_ts`) and read a thread's full reply chain (`conversations.replies`). Covers broadcasting a thread reply back to the channel (`reply_broadcast=true`) and turning any message into a thread by replying to its ts. Trigger on: "reply in thread", "post to that thread", "read the thread", "get all replies", "what's in this thread", "thread from message X", a `slack.com/archives/.../p<ts>?thread_ts=<parent>` URL. For posting a new top-level message use [[slack-send-message]]; for editing a reply use [[slack-edit-message]].
---

# slack-thread — reply in / read a thread

Two methods:

- [`chat.postMessage`](https://docs.slack.dev/reference/methods/chat.postMessage) with `thread_ts` = reply.
- [`conversations.replies`](https://docs.slack.dev/reference/methods/conversations.replies) = read.

## What is `thread_ts`?

The `ts` of the message that STARTED the thread. Any message can
become a thread parent — just reply to its `ts`. Once a thread
exists, the parent's `thread_ts == ts` and `reply_count > 0`.

## Reply in a thread

```bash
slack api chat.postMessage \
  channel=C0123ABC \
  thread_ts=1699999999.000000 \
  text="👍 confirmed"
```

Response `ts` is the reply's own timestamp — use it to reply-to-the-
reply, edit it, react to it, etc.

## Broadcast a reply back to the channel

Ensures the reply also appears in the main channel feed (not just
inside the thread):

```bash
slack api chat.postMessage \
  channel=C0123ABC \
  thread_ts=1699999999.000000 \
  text="TL;DR: rolled back" \
  reply_broadcast=true
```

## Read a thread

```bash
slack api conversations.replies \
  channel=C0123ABC \
  ts=1699999999.000000 \
  limit=200
```

Returns `messages: [parent, reply1, reply2, …]` in chronological
order. Parent is always index 0.

Paginate identically to `conversations.history`
([[slack-read-channel]]) — `response_metadata.next_cursor` /
`has_more`.

## From a `slack.com` permalink

`https://mycorp.slack.com/archives/C0123ABC/p1699999999000000?thread_ts=1699999900.000000&cid=C0123ABC`

- `channel` = `C0123ABC`
- Reading the whole thread: `ts` = `1699999900.000000` (the
  `thread_ts` query param — the PARENT's ts).
- Replying next to that specific message: `thread_ts` =
  `1699999900.000000`, and the individual message you're looking at
  is `1699999999.000000` (from `/pXXXXXXXXXXXXXXXX`, insert `.`
  before the last 6 digits).

## Turn a top-level message into a thread

There's no separate "start a thread" method — just reply with
`thread_ts=<its own ts>`:

```bash
slack api chat.postMessage \
  channel=C0123ABC \
  thread_ts=<orig_ts> \
  text="follow-up context"
```

## Common errors

| Error | Fix |
| --- | --- |
| `thread_not_found` | Parent ts doesn't exist in that channel — double-check ts + channel. |
| `channel_not_found` / `not_in_channel` | Same rules as [[slack-read-channel]] / [[slack-send-message]]. |
| Reply lands as top-level (not in thread) | You passed `ts` instead of `thread_ts`. `ts` is ignored on `postMessage`. |
