---
name: jiraai-commit-check
description: Three-layer Jira ↔ git guardrail. (a) `jiraai-branch <KEY> <slug>` helper creates a compliant `<type>/<KEY>-<slug>` branch from a ticket. (b) `prepare-commit-msg` hook extracts the KEY from the branch name and prepends `[KEY]` to the commit message when missing. (c) `pre-push` hook refuses to push a non-exempt branch that lacks a KEY (bypass: `touch $(git rev-parse --git-dir)/hooks/jiraai-skip`). If no KEY is inferrable on commit, asks the operator whether to create one via `jiraai-mr` or `twg jira workitem create`. Non-interactive contexts (CI, agent runs) warn and pass on prepare-commit-msg, block on pre-push. Triggers on "check my commits for jira id", "enforce jira id in branch name", "wire commits to jira", "no ticket for this commit", "pre-commit hook for jira", "pre-push branch check", "add jira id to commit message", "create a branch for XX-1234". Also triggers implicitly when the agent is about to run `git commit`, `git push`, or `git checkout -b` — inspect the branch first.
---

# jiraai-commit-check — every commit links to a Jira ticket

Three jobs:

1. **Branch creation helper (`jiraai-branch <KEY> <slug>`)**: shape-check
   the input, create a `<type>/<KEY>-<slug>` branch, `git switch -c` it.
   Removes the "I meant to name it right but forgot" failure mode at
   the source.
2. **Auto-prefix (`prepare-commit-msg` hook)**: if the branch contains a
   `PROJ-NNN` and the message doesn't, prepend `[PROJ-NNN]`.
3. **Pre-push refusal (`pre-push` hook)**: refuse to push a non-exempt
   branch without a KEY. Bypass per-branch via `.git/hooks/jiraai-skip`.
   The prepare-commit-msg step is a nudge; this is the hard gate that
   makes the "every branch links to Jira" contract enforceable.

Ask-or-skip: if no KEY can be inferred on commit, prompt the operator
to either create a ticket via `jiraai-mr` / `twg jira workitem create` or skip
forever on this branch.

## Prerequisites

- Read `jiraai` for auth (only needed if creating a ticket on the fly).
- Read `jiraai-mr` for the create-ticket-per-MR orchestrator.

## Branch-name convention

```text
<type>/<KEY>-<slug>            # feat/XX-2601-add-retry-policy
<type>/<KEY>_<slug>            # feat/XX-2601_add-retry-policy
<KEY>-<slug>                   # XX-2601-add-retry-policy (no type prefix)
```

Regex: `\b([A-Z][A-Z0-9_]+-[0-9]+)\b` — first match wins.

## The check (as a hook or as an agent-side pre-flight)

### As a `prepare-commit-msg` hook

```bash
#!/usr/bin/env bash
# ~/.local/share/jiraai/hooks/prepare-commit-msg  (invoked by lefthook or git)
set -eu
MSG_FILE="$1"
COMMIT_SOURCE="${2:-}"

# Skip merge / squash / template / message-provided commits — don't rewrite them
case "$COMMIT_SOURCE" in
  merge|squash|template|message|commit) exit 0 ;;
esac

# Per-branch opt-out
[ -e "$(git rev-parse --git-dir)/hooks/jiraai-skip" ] && exit 0

# Already has a KEY in the message → don't double-prefix
if grep -qE '\[[A-Z][A-Z0-9_]+-[0-9]+\]' "$MSG_FILE"; then exit 0; fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
KEY=$(echo "$BRANCH" | grep -oE '\b[A-Z][A-Z0-9_]+-[0-9]+\b' | head -1 || true)

if [ -n "$KEY" ]; then
  # Prepend "[KEY] " to the first line
  sed -i "1s|^|[$KEY] |" "$MSG_FILE"
  exit 0
fi

# No KEY found — INTERACTIVE branch only
[ -t 0 ] || { echo "jiraai-commit-check: no Jira KEY in branch '$BRANCH' (non-interactive, warning only)" >&2; exit 0; }

echo "" >&2
echo "  ⚠ jiraai-commit-check: no Jira KEY in branch '$BRANCH'" >&2
echo "" >&2
echo "  Options:" >&2
echo "    [c] Create a ticket now (jiraai-mr)" >&2
echo "    [s] Skip forever on this branch (touches .git/hooks/jiraai-skip)" >&2
echo "    [k] Continue without a KEY (this commit only)" >&2
printf "  > " >&2
read -r choice < /dev/tty

case "${choice:-k}" in
  c|C) echo "Run: jiraai-mr new" >&2; exit 1 ;;    # abort → let user do it, then retry
  s|S) touch "$(git rev-parse --git-dir)/hooks/jiraai-skip"; echo "Skipping forever on this branch." >&2; exit 0 ;;
  *)   exit 0 ;;
esac
```

### As an agent-side pre-flight (before firing `git commit`)

Before running `git commit`, do:

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
KEY=$(echo "$BRANCH" | grep -oE '\b[A-Z][A-Z0-9_]+-[0-9]+\b' | head -1 || true)

if [ -z "$KEY" ]; then
  # inspect recent commits on the branch — maybe an earlier commit already established the KEY
  KEY=$(git log --format=%B -20 | grep -oE '\b[A-Z][A-Z0-9_]+-[0-9]+\b' | head -1 || true)
fi

if [ -z "$KEY" ]; then
  # Ask user via a chat prompt: "no Jira ticket linked to this branch. Create one, skip, or continue without?"
  echo "no Jira ticket linked to this branch"
fi
```

Then prepend `[$KEY]` to the commit-msg body IF it's missing:

```bash
git commit -m "$(cat <<EOF
[$KEY] $CONVENTIONAL_TITLE

$BODY
EOF
)"
```

## `jiraai-branch` helper — create a compliant branch from a ticket

Removes the "I forgot to include the KEY" failure mode at the source.
Ship this in `~/.local/share/jiraai/bin/jiraai-branch`, on PATH:

```bash
#!/usr/bin/env bash
# jiraai-branch <KEY> <slug> [<type>]
#   type defaults to 'feat'. Slug is lowercase-kebab.
# Result: git switch -c <type>/<KEY>-<slug>
set -eu
KEY=${1:?KEY required, e.g. PLAT-4039}
SLUG=${2:?slug required, lowercase-kebab}
TYPE=${3:-feat}

# Shape check
echo "$KEY"  | grep -qE '^[A-Z][A-Z0-9_]+-[0-9]+$' || {
  echo "bad KEY '$KEY' — expected PROJ-NNN" >&2; exit 2; }
echo "$SLUG" | grep -qE '^[a-z0-9][a-z0-9-]*$'    || {
  echo "bad slug '$SLUG' — expected lowercase-kebab" >&2; exit 2; }
case "$TYPE" in
  feat|fix|chore|refactor|docs|test|ci|perf) ;;
  *) echo "bad type '$TYPE' — pick feat/fix/chore/refactor/docs/test/ci/perf" >&2; exit 2 ;;
esac

branch="$TYPE/$KEY-$SLUG"
git switch -c "$branch"
echo "Created branch: $branch"
```

Agent-side pre-flight: when the operator says "start work on PLAT-4039",
resolve the ticket summary via `jiraai-review`, propose a slug from the
summary, then run `jiraai-branch PLAT-4039 <slug>`.

## Pre-push branch enforcement (the hard gate)

`prepare-commit-msg` prepends the KEY when a branch has one. It does
NOT enforce that the branch HAS one. Pre-push does. Ship this in
`~/.local/share/jiraai/hooks/pre-push`:

```bash
#!/usr/bin/env bash
# Refuse to push a branch that is expected to link to a Jira ticket
# but lacks a KEY. Reads ref/sha lines from stdin per git pre-push
# protocol.
set -eu

while read -r local_ref _local_sha _remote_ref remote_sha; do
  # Skip deletes
  [ "$remote_sha" = "0000000000000000000000000000000000000000" ] && continue

  branch="${local_ref#refs/heads/}"

  # Exempt: main lines, bot branches, hotfixes, release cuts
  case "$branch" in
    main|master|develop|trunk)                       continue ;;
    renovate/*|dependabot/*|renovate-bot/*|bot/*)    continue ;;
    hotfix/*|release/*)                              continue ;;
  esac

  # Per-branch opt-out (agent won't touch this file — only the operator)
  [ -e "$(git rev-parse --git-dir)/hooks/jiraai-skip" ] && continue

  if ! echo "$branch" | grep -qE '\b[A-Z][A-Z0-9_]+-[0-9]+\b'; then
    echo "" >&2
    echo "  ✗ jiraai pre-push: branch '$branch' has no Jira KEY" >&2
    echo "" >&2
    echo "  Expected: <type>/<KEY>-<slug>  (e.g. feat/PLAT-4039-add-retry)" >&2
    echo "  Helper:   jiraai-branch <KEY> <slug>  (creates the branch)" >&2
    echo "  Bypass:   touch \$(git rev-parse --git-dir)/hooks/jiraai-skip" >&2
    echo "" >&2
    exit 1
  fi
done
```

The regex `\b[A-Z][A-Z0-9_]+-[0-9]+\b` matches the same shape used by
the prepare-commit-msg hook — one source of truth for what counts as a
KEY.

**Design choice — why pre-push, not pre-commit for the enforcement.**
Pre-commit runs on every local commit, including WIP snapshots the
operator may never share. Pre-push is the last chance before origin
sees the branch — matches "no branch reaches teammates without a Jira
link" without slowing local iteration.

## Hook installation (via lefthook, matches this repo's convention)

Add to `lefthook.yaml`:

```yaml
prepare-commit-msg:
  commands:
    jiraai:
      run: ~/.local/share/jiraai/hooks/prepare-commit-msg {1} {2}
      interactive: true

pre-push:
  commands:
    jiraai-branch:
      run: ~/.local/share/jiraai/hooks/pre-push
      # lefthook pipes stdin from git through to the command
```

The dotfiles repo itself does NOT wire pre-push jiraai — this repo
tracks work with beads, not Jira. Wire it into work repos where
every branch should link to a Jira ticket.

The hook lives in the same XDG dir as the config so home-manager can own
both from one module (see `~/.local/share/jiraai/` layout — hooks + config).

## Rules of engagement

- **Never block CI** — the hook exits 0 when `stdin` isn't a TTY.
- **Never block a merge commit** — merges have their own message conventions.
- **Never overwrite an operator-supplied KEY** — the "already has a KEY" check runs BEFORE branch extraction.
- **Skip-forever is per-branch** — deleting the branch removes the flag.
- **When agent-driven**: err toward asking, not silently skipping. A missing Jira link is a signal the workflow was skipped.

## Anti-patterns

- Extracting from CWD path, PR title, or MR description — branch name is the one true source.
- Prefixing with the KEY when the message already has it in a different location (footer, "Refs:") — the check MUST be regex-strict.
- Creating a ticket automatically without asking — no silent side-effects on operator commits.

## Composes with

- **`commit-rationale`**: for the commit body once the KEY is settled
- **`mm-skills-git-commit-craft`**: for the title style + splitting
- **`jiraai-mr`**: the natural "create ticket now" path when the operator answers `c`
- **`twg-jira`**: `twg jira workitem create` — fallback when the operator wants a ticket but not the full MR flow yet
