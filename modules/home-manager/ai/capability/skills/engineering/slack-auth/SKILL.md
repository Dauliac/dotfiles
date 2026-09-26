---
name: slack-auth
description: Log in / out / list / revoke Slack CLI sessions. Slack's official CLI uses an OAuth-session dance — `slack login` prints a challenge string that you paste into a Slack slash command (`/slackauthticket`), the CLI receives an ephemeral session token stored under `~/.slack/`. No manual `xoxp-…` token. Trigger on: "slack login", "log in to slack", "add slack team", "list slack accounts", "which slack am I on", "logout of slack", "revoke slack token", "slack auth test", first-use setup for the parent [[slack]] skill, or any time `slack api` fails with `not_authed` / `invalid_auth`.
---

# slack-auth — Slack CLI session management

`slack` stores tokens under `~/.slack/credentials.json`. One entry
per workspace. Multiple workspaces are supported; disambiguate with
`-w, --team <name-or-id>`.

## Log in

```bash
slack login
```

1. CLI prints a `/slackauthticket <STRING>` command.
2. Paste that command into ANY channel in the target workspace.
3. Slack answers back to the CLI via a webhook; the session token
   lands in `~/.slack/credentials.json`.

Auth code alternative (headless / no browser): `slack login
--no-prompt` and follow the printed auth-ticket challenge flow.

## Verify

```bash
slack auth list         # shows every logged-in team + user
slack api auth.test     # confirms the currently-selected token works
```

## Switch workspace

Global flag `-w, --team` on any command:

```bash
slack -w mycorp api conversations.list
slack -w T0123ABC api conversations.list
```

## Log out / revoke

```bash
slack logout            # removes the local session
slack auth revoke       # revokes the token server-side too
```

## Common failure modes

| Error | Cause / fix |
| --- | --- |
| `not_authed` | No session for this team. Run `slack login`. |
| `invalid_auth` | Session expired or revoked. `slack login` again. |
| `missing_scope` | The OAuth scope for the method wasn't granted at login. Re-login and consent to the required scopes; check `slack api auth.test` output for the current scopes. |
| `token_revoked` | User (or admin) revoked the app. Re-login. |

## Service tokens

`slack auth token` collects a long-lived *service* token (for CI /
deploy pipelines). NOT needed for interactive read/send message
work — that flow uses `slack login`.
