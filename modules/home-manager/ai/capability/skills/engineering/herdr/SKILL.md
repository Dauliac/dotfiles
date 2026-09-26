---
name: herdr
description: Terminal workspace manager for AI coding agents — sessions, workspaces, panes, worktrees, tabs, and agent integrations over a socket API. Trigger when you need to manage the terminal workspace itself: create a session, list/pick panes, inspect a workspace, attach to a remote session, drive an agent through the integration layer. For "run this command in a visible pane" prefer the `herdr-run` skill — that's the specialized workflow layered on top of raw herdr.
---

# herdr — terminal workspace over a socket API

`herdr` runs a headless server per user and exposes it through a socket
API. Every workflow-facing action — split a pane, list workspaces, wait
for output, drive an agent — is a subcommand on that API.

## When to reach for it

- Managing the workspace itself: sessions, workspaces, tabs, panes,
  worktrees.
- Waiting for output from another pane (`herdr pane wait-output`) —
  the primitive `herdr-run` is built on.
- Attaching to a remote herdr server through SSH.
- Introspecting server / client state (`herdr status`, `herdr api …`).
- Managing built-in agent integrations (`herdr integration …`).

For the common "split-and-run" case, use the `herdr-run` skill — it
wraps pane creation + output capture into a single ergonomic call.

## Top-level surface

| Subcommand | Purpose |
|---|---|
| `herdr`                          | Launch / attach the persistent session |
| `herdr status [server\|client]`  | Show local + server state |
| `herdr session <sub>`            | Manage named persistent sessions |
| `herdr workspace <sub>`          | Workspace helpers |
| `herdr worktree <sub>`           | Git worktree helpers |
| `herdr tab <sub>`                | Tab helpers |
| `herdr pane <sub>`               | Pane helpers (split, list, wait-output, kill) |
| `herdr agent <sub>`              | Agent / terminal helpers |
| `herdr notification <sub>`       | Notification helpers |
| `herdr integration <sub>`        | Built-in agent integrations |
| `herdr api <sub>`                | Raw socket API metadata / runtime |
| `herdr config <sub>`             | Config helpers |
| `herdr channel <sub>`            | stable / preview update channel |
| `herdr update [--handoff]`       | Download + install latest |
| `herdr server stop`              | Stop the running server via socket |
| `herdr server reload-config`     | Reload `config.toml` in the running server |
| `herdr completion <shell>`       | Generate shell completion |
| `--remote <ssh-target>`          | Attach through SSH to remote server |
| `--session <name>`               | Use / create a named session |
| `--skill`                        | Print the agent skill file (built-in guidance) |

Config: `~/.config/herdr/config.toml`.

## Recipes

**Discover panes** and address one by id:

```bash
herdr pane list                              # human table
herdr pane list --json | jq                  # scriptable
herdr pane get <pane-id>                     # metadata for one pane
```

**Split, run in the new pane, wait for a completion marker**:

```bash
new_id=$(herdr pane split --direction right --json | jq -r .id)
herdr pane send-keys --pane "$new_id" "cargo build && echo DONE-42"
herdr pane wait-output --pane "$new_id" --regex 'DONE-42' --timeout 300000
```

Higher-level equivalent: `herdr-run cargo build` — see `herdr-run`.

**Attach to a remote server** through SSH:

```bash
herdr --remote user@host --session default
```

**Introspect the socket API** (when writing scripts against herdr):

```bash
herdr api list-methods           # available methods
herdr api schema <method>        # I/O schema for one
```

**Sessions** for parallel workflows:

```bash
herdr session list
herdr --session support-2026-09-08     # named session per day of support
```

## Gotchas

- `herdr` (bare) tries to attach or launch — use subcommands for
  scripted work, never bare `herdr` inside a script.
- Pane IDs are ephemeral to the server lifetime — capture and reuse
  within a session; don't hard-code them.
- `--handoff` on `update` / remote attach hands the running TTY
  across — safe interactively, dangerous in scripts.
- `herdr channel set preview` opts you into the preview update
  channel — don't flip it without the user asking.
- The state file for `herdr-run`'s persistent pane lives at
  `$XDG_RUNTIME_DIR/herdr-run/pane-<sha1(cwd|role)>.id` — clean it
  with `herdr-run --forget` when a pane is dead.

## Composes with

- **herdr-layout**: create / rename / move / close panes, tabs,
  workspaces, worktrees — the CRUD verbs on top of raw `herdr <noun>`.
- **herdr-find**: `--json` + jq recipes to discover panes/tabs/
  workspaces/agents by label, cwd, terminal title, or agent state.
- **herdr-run**: split-and-capture — the daily driver on top of raw
  `herdr pane`.
- **tui-context**: opens context-aware TUIs (k9s, glab ci view, stu,
  lazygit) in herdr splits with sensible layout.
- **ci-watch / k8s-watch / s3-watch**: domain-specific TUIs on top of
  herdr splits.
