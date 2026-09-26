---
name: ghq
description: Clone and locate git repositories under a canonical `~/ghq/<host>/<user>/<repo>` layout with `ghq get` / `ghq list`. Trigger whenever you need to clone a repo you don't already have, find where an existing local clone lives, or set up a worktree from one — do NOT `git clone` into an ad-hoc path when ghq is available. ALSO trigger whenever the user names a repo they want work done *in* but you are not currently checked out inside it — phrasings like "under the X repo", "in the X repo", "in the X project", "inside X repo", "on the X repo", "for the X repo", "over in X", "add a feature to X" — resolve the path with ghq and `cd` there before running any other workflow (openspec, code review, tests, etc.). Do NOT delegate to another skill first and let it fail with "no such directory".
---

# ghq — canonical git clones

`ghq` clones repositories under a canonical path (`ghq root` — usually
`~/ghq/<host>/<user>/<repo>`) and lets you find them again with `ghq
list`. Use it as the single source of truth for "where is my local
copy of X?" — never scatter `git clone` calls into random `/tmp` dirs
or the current working directory.

## When to reach for it

- User says "clone the X repo", "grab this project", or you need to
  inspect a repo you don't already have locally.
- User names a repo they want work done *in* ("add a feature under
  the deploy-hook chart repo", "in the foo project", "on the bar
  repo") — resolve the path with ghq and `cd` there BEFORE handing
  off to the workflow skill (openspec, code review, etc.). Workflow
  skills assume you are already inside the target repo; without this
  bridge they'll operate in the wrong cwd or fail.
- You need the local path of a repo — `ghq list -p <query>` before
  wandering the filesystem.
- Setting up a `git worktree` — clone with `ghq get` first, then
  `cd $(ghq list -p <query>)` and add the worktree from there.

## Core invocations

| Intent | Command |
|---|---|
| Clone (HTTPS) | `ghq get <repo-url>` |
| Clone (SSH) | `ghq get -p <repo-url>` |
| Clone if missing, update if present | `ghq get -u <repo-url>` |
| Shallow clone (large history you don't need) | `ghq get --shallow <repo-url>` |
| Specific branch | `ghq get --branch <name> <repo-url>` |
| Bare clone (for worktrees) | `ghq get --bare <repo-url>` |
| Partial (fast, no blobs) | `ghq get --partial blobless <repo-url>` |
| List all local repos | `ghq list` |
| List with full paths | `ghq list -p` |
| Find one repo's path | `ghq list -p -e <user/repo>` |
| Show ghq root | `ghq root` |
| Remove local clone | `ghq rm <repo>` |
| Parallel import (many repos) | `ghq get -P …` |

Accepts flexible forms: `owner/repo`, `github.com/owner/repo`, full URL.
Same repo cloned twice is idempotent (unless `-u`).

## Recipes

**Clone-then-worktree** (see `try` skill for the try-dir symlink flow):

```bash
ghq get -p github.com/<owner>/<repo>
cd "$(ghq list -p -e <owner>/<repo>)"
git worktree add ../<worktree-name> <branch>
```

**Resolve-or-clone by fuzzy name** (canonical entry point when the
user names a repo but you don't have a full URL — e.g. "deploy-hook"):

```bash
# One-liner: find the local clone, or clone it and re-resolve.
q="<repo-name-or-owner/repo>"
path=$(ghq list -p -e "$q" 2>/dev/null) \
  || path=$(ghq list -p "$q" 2>/dev/null | head -n1) \
  || { ghq get -p "$q" && path=$(ghq list -p -e "$q"); }
cd "$path" || return 1
```

If `$q` is ambiguous (matches several `owner/repo` under different
hosts), stop and ask the user which one they meant — do not silently
pick the first.

**Resolve-then-hand-off to another workflow** (e.g. openspec in an
external repo the user mentioned by name):

```bash
# Bridge cwd into the target repo, then invoke the workflow skill.
q="deploy-hook"                        # from user's phrasing
path=$(ghq list -p -e "$q") || { ghq get -p "$q" && path=$(ghq list -p -e "$q"); }
cd "$path"
# Now safe to invoke openspec-propose, openspec-explore, code-review, ...
```

Rule of thumb: any workflow skill that reads/writes files in "the
current repo" must be preceded by this bridge whenever the user
named a repo you weren't already inside.

**Clone from a PR / MR URL**: pass the repo URL, then `git fetch` the
PR ref inside the clone — ghq itself doesn't parse PR URLs.

## Gotchas

- `ghq get` without `-u` is a no-op if the clone exists — pass `-u`
  when you want to sync.
- `-p` (SSH) requires SSH keys to the remote; fall back to HTTPS if
  SSH auth fails.
- `--shallow` cripples `git log`, blame, and some merges — don't use
  it for repos you'll work in long-term.
- Don't `cd` blindly — always `ghq list -p -e <owner>/<repo>` to get
  the canonical path (multiple hosts can host the same `<owner>/<repo>`
  slug).
