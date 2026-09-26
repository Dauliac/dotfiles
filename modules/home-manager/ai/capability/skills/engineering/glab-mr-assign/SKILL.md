---
name: glab-mr-assign
description: Add / remove MR reviewers and assignees WITHOUT the two footguns — (a) verify usernames exist via `glab api "users?search=…"` before calling `glab mr update`, and (b) use `+username` / `-username` semantics so a `--reviewer` call ADDS instead of REPLACING the existing list. Trigger on "set X as reviewer", "add reviewer", "assign the MR to me", "reassign MR", "remove reviewer", "who can review this". Never accept first-name guesses ("brice", "sofiane") without resolving to a real username first.
---

# glab-mr-assign — resolve users, then add without clobbering

Fixes two recurring failure modes:

1. **First-name guess silently no-ops**. `glab mr update <IID>
   --reviewer brice` accepts the input; GitLab's `?username=brice`
   filter is exact-match and returns empty, so no reviewer is added,
   no error propagates to a human-readable message. Result:
   `reviewers: []`, operator thinks the reviewer is set.
2. **Default `--reviewer` REPLACES the existing list**. Passing
   `--reviewer reviewer-b` when the MR already had `reviewer-a`
   leaves only Sofiane. Same for `--assignee`.

## The two glab flags — distinct, easy to confuse

| Flag | Purpose | Short |
| --- | --- | --- |
| `--assignee` | Sets the assignee (owner) | `-a` |
| `--reviewer` | Requests review | (no short) |

`-r` on `glab mr update` is `--ready` (mark ready-for-review),
**not** `--reviewer`. Do not confuse.

## Semantics — add / remove / replace

Both flags share the prefix convention from `glab mr update --help`:

| Prefix | Behavior |
| --- | --- |
| `+username` | **ADD** to the existing list |
| `-username` | REMOVE from the existing list |
| `!username` | REMOVE (alias for `-`) |
| `username`  | REPLACE — kicks out everyone else |

**Default (no prefix) is REPLACE** — this is the footgun. Always
use `+` when adding, `-` when removing.

## Step 1 — Resolve any user input to a real username

**NEVER pass a first-name guess to `--reviewer` / `--assignee`.**
Wrap through a resolver first:

```bash
# glab-mr-verify-users — one line per input; exits non-zero if any
# resolves to zero matches. Prints the resolved username on success.
# Prefers exact ?username=... match; falls back to ?search=... prefix.
glab_resolve_user() {
  local q="$1"
  # Exact match first — cheapest, works for "reviewer-a"
  local u
  u=$(glab api "users?username=$q" 2>/dev/null | jq -r '.[0].username // empty')
  if [ -n "$u" ]; then printf '%s\n' "$u"; return 0; fi
  # Fallback — search prefix, must return exactly one
  local hits
  hits=$(glab api "users?search=$q" 2>/dev/null \
    | jq -r '.[] | "\(.username)\t\(.name)"')
  local n
  n=$(printf '%s\n' "$hits" | grep -c . || true)
  case "$n" in
    0) echo "no user matches '$q'" >&2; return 2 ;;
    1) printf '%s\n' "$hits" | cut -f1 ;;
    *) echo "'$q' is ambiguous:" >&2
       printf '%s\n' "$hits" >&2
       return 3 ;;
  esac
}

# Usage: resolve two first-name guesses to real usernames
BRICE=$(glab_resolve_user brice)      # → reviewer-a
SOFIANE=$(glab_resolve_user sofiane)  # → reviewer-b
```

Ambiguity is a signal, not a defeat — surface all matches to the
operator so they can pick. Never auto-pick.

## Step 2 — Add / remove without clobbering

**Add one reviewer** (keep existing):

```bash
glab mr update <IID> --reviewer "+$BRICE"
```

**Add multiple reviewers** in one call (comma-separated or repeat):

```bash
glab mr update <IID> --reviewer "+$BRICE,+$SOFIANE"
# or
glab mr update <IID> --reviewer "+$BRICE" --reviewer "+$SOFIANE"
```

**Remove one reviewer** (keep everyone else):

```bash
glab mr update <IID> --reviewer "-$BRICE"
```

**Set assignee to me** (self-owned MR):

```bash
glab mr update <IID> --assignee @me
# NOTE: @me is a glab-side alias; the exact expansion happens
# server-side. Also works: --assignee "$(glab api /user | jq -r .username)".
```

**Add me as an additional assignee** (multi-assignee projects):

```bash
ME=$(glab api /user | jq -r .username)
glab mr update <IID> --assignee "+$ME"
```

**Unassign everyone**:

```bash
glab mr update <IID> --unassign
```

## Step 3 — Verify the mutation landed

Silent failure is the whole problem. Always confirm:

```bash
glab mr view <IID> --output json \
  | jq '{
      reviewers:[.reviewers[]?.username],
      assignees:[.assignees[]?.username]
    }'
```

If the expected username is missing, **do not report success**. Loop
back to Step 1 — the input probably didn't resolve.

## Discovering who is eligible

For approval-gated MRs, the eligible approver pool comes from the
`approval_state` endpoint (see `glab-mr-ready`):

```bash
PROJ=$(glab api "projects/$(printf '%s' "<group/project>" | jq -sRr @uri)" | jq -r .id)
glab api "projects/$PROJ/merge_requests/<IID>/approval_state" \
  | jq -r '.rules[]?.eligible_approvers[]?.username' | sort -u
```

For a git-file-owner heuristic (who last touched the changed
files — usually a good first reviewer):

```bash
git log -n 1 --format='%an <%ae>' -- <changed-file>
```

Map name → username via `glab_resolve_user` (Step 1).

## Gotchas

- `--reviewer` with no prefix REPLACES. Assume `+` unless the
  operator explicitly asked to reset.
- `@me` works in glab but does not survive server-side introspection
  in some responses — always verify via `glab mr view --output json`.
- `--assignee` on projects with single-assignee mode ignores multiple
  entries — GitLab picks the first.
- Reviewer removal via `-username` requires the exact username
  (not `+` and not the display name).
- Some self-hosted GitLabs restrict `users?search=` to admins —
  fallback: paginate `users?per_page=100` and grep locally, or ask
  the operator for the exact username.

## Composes with

- **glab-mr-open** — creates the MR with the correct initial
  reviewer list.
- **glab-mr-ready** — reads `approval_state` to know who MUST
  approve; feed that pool into `glab_resolve_user`.
- **mm-skills-gitlab-mr** — `prepare-for-review.md` covers the
  ManoMano review-request etiquette (who to ping, when to nudge).
