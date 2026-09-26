---
name: glab
description: Interact with GitLab from the CLI — issues, merge requests, CI/CD pipelines and jobs, snippets, releases, API. Trigger on any GitLab task: "check pipeline", "open MR", "read this issue", "download job log", "get CI status", or a `gitlab.com` / self-hosted GitLab URL. Prefer glab over the raw REST API and over opening the web UI.
---

# glab — GitLab from the terminal

`glab` is the official GitLab CLI. It authenticates once (`glab auth
login`) and covers almost every GitLab surface — issues, merge
requests, CI/CD, pipelines, jobs, releases, snippets, and a raw
`glab api` escape hatch for anything else.

## When to reach for it

- You need to read or comment on a GitLab issue, MR, or pipeline.
- Investigating a failed CI job — `glab ci …` is faster than the web
  UI and returns log text you can grep.
- Creating or updating an MR from a branch.
- Anything on `gitlab.com` or a self-hosted GitLab instance the user
  is authenticated against.

Do NOT use it for GitHub (that's `gh`), and don't reach for `curl` on
the GitLab REST API when a `glab` command exists.

## Core surface

| Domain | Common subcommands |
|---|---|
| `glab issue`  | `list`, `view <id>`, `create`, `close`, `reopen`, `note <id> -m …`, `subscribe` |
| `glab mr`     | `list`, `view <id>`, `create --fill`, `merge <id>`, `note <id> -m …`, `approve`, `rebase`, `checkout <id>` |
| `glab ci`     | `list`, `view` (TUI), `get`, `status`, `retry`, `cancel`, `run`, `artifact <ref> <job>`, `config lint`, `trace <job>` |
| `glab job`    | `artifact <job-id>`, `log <job-id>` |
| `glab release`| `list`, `view <tag>`, `create <tag>`, `download <tag>` |
| `glab snippet`| `create`, `list`, `view <id>` |
| `glab api`    | `<endpoint>` — raw REST for anything not covered |
| `glab auth`   | `login`, `status`, `token` |
| `glab config` | `get`/`set <key> <value>` — including per-host defaults |
| `glab repo`   | `view`, `clone`, `fork`, `create` |
| `glab variable` | `list`, `set`, `delete`, `get` — CI/CD variables |
| `glab schedule` | `list`, `run <id>`, `create`, `delete` |
| `glab search`   | `<query>` — code + resources (BETA) |

Use `--repo <group/project>` to target a project other than the
current git repo. Use `--output json` (where supported) for
structured output.

## Common recipes

**Read a ticket / MR / pipeline from a URL**:

```bash
glab issue view <id-or-url>
glab mr view <id-or-url>
glab ci view          # picks the pipeline on the current branch
```

**Failed job triage**:

```bash
glab ci status                          # latest pipeline
glab ci get                             # pipeline metadata + jobs
glab job log <job-id>                   # full log
glab ci artifact <ref> <job-name>       # download artifacts
```

**Open an MR from the current branch**:

```bash
glab mr create --fill --draft --label bug   # `--fill` uses commit msg
glab mr view --web                          # open in browser after
```

**Comment on an issue / MR**:

```bash
glab issue note <id> -m "reproduced on ML-PF603JJ8, see !4321"
glab mr note <id> -m "rebased on top of main, ready for another look"
```

**Raw API call** (anything not wrapped):

```bash
glab api projects/:id/issues?labels=bug,triage --paginate
glab api "projects/<url-encoded-path>/pipelines/<pid>/jobs"
```

## Gotchas

- Some subcommands are marked EXPERIMENTAL / BETA (`mcp`, `search`,
  `security`, `orbit`, `skills`) — treat their output as unstable.
- `glab ci view` is a TUI — pair with the **ci-watch** skill so the
  user watches it in a herdr split rather than blocking your call.
- `glab mr create --fill` needs a pushed branch with commits distinct
  from `main` — pushes if needed, but requires an upstream.
- `--repo` must be `group/project` (or full URL), not just the repo
  slug.
- Auth is per-host — `glab auth login --hostname <self-hosted>` for
  private instances.

## Composes with

- **ci-watch**: opens `glab ci view` in a herdr split scoped to the
  affected branch so pipeline progress is visible.
- **jira-explore / jira-fix**: when a ticket references a GitLab MR
  or pipeline, use `glab mr view` / `glab ci view` to gather facts
  for `proof.md`.
