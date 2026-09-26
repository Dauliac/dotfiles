---
name: slack
description: Slack's official platform CLI (`slack`, `github.com/slackapi/slack-cli`) — talk to any Slack Web API method from the terminal via `slack api <method>`. Auth is OAuth-session via `slack login` (no manual `xoxp-…` token). Reach for it any time the user wants to read a Slack channel, post a message, DM someone, react, edit/delete a message, upload a file, or hit a Web API method by name. Trigger on: "post to slack", "read slack channel", "slack DM", "send a slack message", "search slack", "slack api", "who's in this channel", "channel id for #foo", "react to that message", `slack.com` URLs, or a message permalink. For actual message send/read, prefer the atomic sub-skills (slack-send-message, slack-read-channel, slack-thread, slack-search, …) — this parent skill is the map. Does NOT cover Slack app / workflow / manifest / datastore / trigger commands — that's a separate concern the user has explicitly scoped out.
---

# slack — Slack from the terminal

`slack` is Slack's OFFICIAL platform CLI (binary from
`github.com/slackapi/slack-cli`, distinct from `pkgs.slack-cli` which
is a Bash Web-API wrapper by rockymadden). It authenticates via an
OAuth session (`slack login` prints a challenge string → paste into a
Slack slash command → CLI receives an ephemeral session token stored
under `~/.slack/`). No `xoxp-…` token to store in sops.

## When to reach for it

- Read or post a message in a channel / DM / thread.
- Look up channel or user IDs.
- Search messages across a workspace.
- Call any Slack Web API method by name — `slack api <method>`.

Do NOT use it for Slack app development (`slack create`, `slack
deploy`, `slack run`, manifest / trigger / function / datastore /
sandbox commands). The user has explicitly scoped those out.

## The one command that matters: `slack api`

Every messaging operation is a `slack api <method>` call. The CLI
wraps Slack's Web API 1:1 — same method names as
https://docs.slack.dev/reference/methods.

```bash
# form-encoded (default, key=value positional args)
slack api chat.postMessage channel=C0123ABC text="hello"

# JSON body (for nested payloads like blocks)
slack api chat.postMessage --json '{"channel":"C0123ABC","blocks":[…]}'

# Test auth
slack api auth.test
```

Token resolution priority: `--token` > `--app` > `SLACK_BOT_TOKEN`
env > `SLACK_USER_TOKEN` env > interactive app prompt.

## Atomic sub-skills (the map)

Load only the sub-skill for the operation at hand — do NOT read all
of them.

| Skill | Purpose |
| --- | --- |
| [slack-auth](../slack-auth/SKILL.md) | `slack login` OAuth-session dance, list/logout/revoke |
| [slack-api](../slack-api/SKILL.md) | The generic `slack api` escape hatch — payload shapes, pagination, rate limits |
| [slack-send-message](../slack-send-message/SKILL.md) | `chat.postMessage` — post to channel or DM |
| [slack-read-channel](../slack-read-channel/SKILL.md) | `conversations.history` — read messages with pagination |
| [slack-thread](../slack-thread/SKILL.md) | Post a thread reply (`thread_ts`) + read thread replies |
| [slack-search](../slack-search/SKILL.md) | `search.messages` — text search across the workspace |
| [slack-list-channels](../slack-list-channels/SKILL.md) | `conversations.list` — resolve channel names → IDs |
| [slack-list-users](../slack-list-users/SKILL.md) | `users.list` / `users.lookupByEmail` — resolve user identity |
| [slack-react](../slack-react/SKILL.md) | `reactions.add` / `reactions.remove` |
| [slack-edit-message](../slack-edit-message/SKILL.md) | `chat.update` / `chat.delete` |
| [slack-upload-file](../slack-upload-file/SKILL.md) | Upload a file via the current 3-step external-URL flow |

## Global flags that matter

- `-w, --team <name-or-id>` — pick workspace when logged into several.
- `--token <value>` — override token resolution (bypass session).
- `-v, --verbose` — dump the HTTP request and response for debugging.
- `-i, --include` — include response headers (useful for rate-limit inspection: `Retry-After`, `X-Rate-Limit-*`).

## Prerequisites for every sub-skill

1. `slack auth list` returns at least one team — otherwise run `slack
   auth login` first (see [slack-auth](../slack-auth/SKILL.md)).
2. The session token has the OAuth scopes the target method requires.
   `slack api auth.test` reveals the current user/team.
