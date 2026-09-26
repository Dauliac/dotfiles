---
name: glab-mr-title
description: Canonicalise an MR title in place — dedupe `Draft: Draft:` / `WIP: WIP:` prefixes, prepend `[TICKET-ID]` derived from the branch when missing, keep conventional-commits shape (`type(scope): subject`). Trigger on "fix MR title", "the title has double Draft", "add the ticket id to the MR title", "clean the title of !123", "rewrite title", or as the "dirty title" action inside `glab-mr-ready`. Never rewrites a title that already matches the canonical shape.
---

# glab-mr-title — one canonical MR title

Canonical shape: `[<TICKET-ID>] <conventional-commit-title>`, with at
most one `Draft: ` / `WIP: ` prefix (added by glab when the MR is
draft, NOT by the operator).

Two failures this skill fixes:

1. `Draft: Draft: chore(dns): ...` — glab prepends `Draft:` on
   `--draft`, even if the operator's title already started with it.
2. `chore(dns): remove hostnames` on branch `PLAT-4012-…` — no
   ticket ID in the title, so nobody can trace the MR to Jira from
   the title bar.

## Prerequisites

- `glab auth status` OK on the target host.
- MR exists (IID + repo).

## The canonical shape

```text
[<TICKET>] <type>(<scope>): <subject>
    where:
      <TICKET>  matches \b[A-Z][A-Z0-9]+-[0-9]+\b        e.g. PLAT-4012
      <type>    is one of feat|fix|chore|docs|refactor|test|build|ci
      <scope>   optional short kebab, in parens
      <subject> imperative, ≤ 72 chars, no trailing period
```

`Draft: ` / `WIP: ` prefixes are managed by glab (`--draft` /
`--ready`) — the operator MUST NOT include them in the title
string.

## The rewrite

```bash
export GITLAB_HOST=<self-hosted-host-if-any>
REPO=<group/subgroup/project>
IID=<mr-iid>

OLD=$(glab mr view "$IID" --repo "$REPO" --output json | jq -r '.title')
BRANCH=$(glab mr view "$IID" --repo "$REPO" --output json | jq -r '.source_branch')

# Step 1: strip ALL leading Draft:/WIP: prefixes (glab will re-add
# exactly one if the MR is still draft).
NEW=$(printf '%s' "$OLD" | sed -E 's/^(Draft:|WIP:)[[:space:]]*//g')
# Loop for double-prefix like "Draft: Draft: …"
while printf '%s' "$NEW" | grep -qE '^(Draft:|WIP:)'; do
  NEW=$(printf '%s' "$NEW" | sed -E 's/^(Draft:|WIP:)[[:space:]]*//')
done

# Step 2: derive ticket ID from branch, prepend if missing.
TICKET=$(printf '%s' "$BRANCH" | grep -oE '\b[A-Z][A-Z0-9]+-[0-9]+\b' | head -1)
if [ -n "$TICKET" ]; then
  case "$NEW" in
    *"[$TICKET]"*|"$TICKET"*) : ;;    # already present
    *) NEW="[$TICKET] $NEW" ;;
  esac
fi

if [ "$OLD" = "$NEW" ]; then
  echo "Title already canonical: $OLD"
  exit 0
fi

echo "OLD: $OLD"
echo "NEW: $NEW"
echo "Confirm rewrite? [y/N]"
read -r answer < /dev/tty
[ "$answer" = "y" ] || exit 1

glab mr update "$IID" --repo "$REPO" --title "$NEW"

# Verify
glab mr view "$IID" --repo "$REPO" --output json | jq -r '.title'
```

## What the skill deliberately does NOT do

- **Does not touch the description** — that's `mm-skills-gitlab-mr`
  `references/update-description.md`.
- **Does not toggle draft/ready** — that's a semantic change (see
  `glab-mr-ready`), not a title canonicalisation.
- **Does not translate or paraphrase the subject** — only strips
  redundant prefixes and prepends the ticket ID.
- **Does not enforce a specific `<type>`** — if the operator wrote
  `wip(dns): ...` intentionally, leave it. Warn only.

## Edge cases

- **Branch has no ticket ID** — leave the title as-is after
  dedupe. Warn: "no ticket ID in branch '$BRANCH' — title left
  without prefix". The operator can pass one explicitly via
  `glab mr update $IID --title "[MANUAL-KEY] …"`.
- **Multiple ticket IDs in branch** (`PLAT-1234-fixes-PLAT-1230`) —
  use only the first match. If the operator wanted both, ask them.
- **Title is empty** — refuse. `glab mr create` requires a
  non-empty title.
- **Non-conventional-commits title** — warn but do not rewrite.
  Style is separate from correctness.

## Composes with

- **glab-mr-open** — sets a canonical title on creation; this
  skill exists for MRs that were opened without it.
- **glab-mr-ready** — the "dirty title" action delegates here.
- **jiraai-commit-check** — prepends `[TICKET]` to commit
  messages; this skill mirrors that convention on the MR title.
- **mm-skills-git-commit-craft** — for the `<type>(<scope>):
  <subject>` shape guidance.
