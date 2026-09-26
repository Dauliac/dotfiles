---
name: dust
description: Chat with a Dust agent from the CLI (`dust chat`) for non-interactive investigations, plans, or follow-ups. Trigger on "ask dust", "dust agent", "Dust conversation", or when the user wants a second opinion / long-context reasoning from a Dust workspace agent. Persists one conversation per task via `--conversationId` — reuse the same ID for follow-ups so the Dust agent keeps its own memory of the task.
---

# dust — Dust CLI for scripted agent calls

`dust` (npm `@dust-tt/dust-cli`) opens a chat with a Dust workspace agent.
The value for coding agents is `dust chat --message …` — a non-interactive
call that returns JSON and lets you keep a persistent conversation across
separate Claude Code sessions via `--conversationId`.

## When to reach for it

- User asks for a Dust agent's take on a design, ticket, incident, spec.
- You need long-context reasoning against Dust's indexed workspace
  (Notion, Slack, Confluence, GitHub) — Claude Code can't see those.
- You're continuing a multi-step investigation the Dust agent already
  helped with — reuse the persisted conversation ID.

Do NOT use it for one-shot facts you already have, or for anything
where you'd rather reason yourself.

## Core invocations

| Intent | Command |
|---|---|
| Send a one-shot message, get JSON back | `dust chat --agent "<name>" --message "<text>"` |
| Continue a prior conversation | `dust chat --agent "<name>" --conversationId "<id>" --message "<text>"` |
| Select agent by system id (stable) | `dust chat --sId <sId> --message "<text>"` |
| Show detailed message info | `dust chat --agent "<name>" --message "<text>" --details` |
| Fetch a specific message | `dust chat --agent "<name>" --conversationId "<id>" --messageId "<mId>"` |
| Interactive chat (skip in scripts) | `dust chat --agent "<name>"` |
| Auth | `dust login` (OAuth) or `DUST_API_KEY` + `DUST_WORKSPACE_ID` env |
| Check auth | `dust status` |
| Clear agents cache | `dust cache:clear` |

Non-interactive response shape:

```json
{
  "conversationId": "…",
  "messageId": "…",
  "agentAnswer": "…"
}
```

## Conversation persistence — one conversation per task

Dust conversations survive across Claude Code sessions. Reuse them or
you throw away the Dust agent's memory of the task.

**Rule**: one conversation per Jira ticket, incident, feature, or
investigation. Do NOT mix unrelated tasks in the same conversation —
the Dust agent will pollute one topic with another.

**Store the ID next to the work**:

```bash
mkdir -p .dust
# after first call, extract .conversationId from JSON:
echo "<returned-id>" > .dust/conversation-id
```

For ticket work (see `jira-ticket` skill), use per-ticket paths:

```bash
mkdir -p ~/src/tries/$(date +%F)-support/<TICKET-ID>/.dust
```

**Reuse on every follow-up**:

```bash
dust chat --agent "<name>" \
  --conversationId "$(cat .dust/conversation-id)" \
  --message "Continue from the previous analysis. Next question: …"
```

If `.dust/conversation-id` doesn't exist, run the first call without
`--conversationId`, parse `.conversationId` from the JSON response,
persist it, then use it for every subsequent call in that task.

Add `.dust/` to `.gitignore` when the ID is local-only.

## Scripting recipe

```bash
# First call — start a conversation, capture the id
out=$(dust chat --agent "dust" --message "<initial question>")
cid=$(printf '%s' "$out" | jq -r '.conversationId')
printf '%s' "$cid" > .dust/conversation-id
printf '%s' "$out" | jq -r '.agentAnswer'

# Follow-up — reuse the id
dust chat --agent "dust" \
  --conversationId "$(cat .dust/conversation-id)" \
  --message "<follow-up>" | jq -r '.agentAnswer'
```

## Gotchas

- `--message` requires `--agent` (or `--sId`).
- Non-interactive calls **consume credits**; interactive `dust chat`
  counts as human usage. Don't loop scripted calls carelessly.
- `--with-tools` (`-t`) **auto-approves every tool the Dust agent runs
  on the local filesystem, including file edits and shell commands**.
  Do not pass it unless the user asked for it explicitly.
- Env vars (`DUST_API_KEY`, `DUST_WORKSPACE_ID`) take precedence over
  the equivalent flags — check `dust status` if auth is confusing.
- Dust context ≠ Claude Code context. The `--conversationId` restores
  Dust's memory of the thread, not yours.

## Composes with

- **jira-ticket**: creates the per-ticket `.dust/conversation-id`
  under the try dir; explore/fix/answer steps reuse that same ID.
- **beads**: attach the Dust conversation ID and messageId of the
  key exchange to the bead note so future sessions can pick it up.
