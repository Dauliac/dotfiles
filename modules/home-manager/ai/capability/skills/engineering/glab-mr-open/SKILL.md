---
name: glab-mr-open
description: Open a new GitLab MR the right way — parse ticket ID from branch, embed it as `[TICKET-ID]` prefix in the title (refuse if missing), self-assign, verify each requested reviewer's username exists BEFORE calling glab, put the Jira URL in the description (not just a comment), then delegate reciprocal Jira remoteLink to `jiraai-link`. Trigger on "open the MR", "push and create the MR", "create a draft MR for this branch", "PR this branch", "MR for PLAT-1234". Never leaves reviewers/assignee empty, never lets `glab mr create --draft` add a duplicate `Draft:` prefix.
---

# glab-mr-open — safe MR creation with the boring stuff wired

Fixes four recurring failures previous claude produced:

1. `assignees: []` — nobody owns the MR.
2. `reviewers: []` — `--reviewer <bad-username>` silently no-op'd.
3. Title missing `[TICKET-ID]` — no cross-link with Jira.
4. `Draft: Draft:` — `--draft` double-prefixed a title that already
   contained "Draft:".

## Prerequisites

- `glab auth status` returns OK on the target host (self-hosted:
  `GITLAB_HOST=$GITLAB_HOST`).
- Branch is pushed to the remote.
- If linking to Jira: `~/.config/sops-nix/secrets/atlassian_api_token`
  present + `~/.local/share/jiraai/config.yaml` populated (see
  `jiraai`).

## Non-negotiables

- **Assignee**: always `--assignee @me`. An MR without an owner rots.
- **Ticket ID in title**: parse `\b[A-Z][A-Z0-9]+-[0-9]+\b` from the
  branch name; refuse to open the MR if neither branch nor
  operator-supplied title carries one (unless operator explicitly
  passes `--no-ticket` — non-default; log why).
- **Reviewers verified first**: NEVER pass a first-name guess. See
  `glab-mr-assign` — it wraps `glab api "users?search=<q>"` to
  resolve the real `username`, and uses `+username` semantics so a
  later `--reviewer` call adds instead of replaces.
- **Title canonicalization**: strip a leading `Draft:` / `WIP:` from
  the operator-supplied title before passing to `glab mr create
  --draft` — glab prepends its own.

## The safe recipe

```bash
export GITLAB_HOST=<self-hosted-host-if-any>
BRANCH=$(git rev-parse --abbrev-ref HEAD)
TICKET=$(printf '%s' "$BRANCH" | grep -oE '\b[A-Z][A-Z0-9]+-[0-9]+\b' | head -1)

if [ -z "$TICKET" ]; then
  echo "Refusing: branch '$BRANCH' has no ticket ID (regex \b[A-Z]…-[0-9]+\b)." >&2
  echo "Rename with: git branch -m <type>/<TICKET-ID>-<slug>" >&2
  exit 1
fi

# Operator-supplied title (short, imperative, conventional-commits shape)
TITLE_RAW="chore(dns): remove 4 obsolete legacy hostnames from corp.example"
# Strip leading Draft:/WIP: — glab --draft will add it back once
TITLE=$(printf '%s' "$TITLE_RAW" | sed -E 's/^(Draft:|WIP:)[[:space:]]*//')
# Prefix with ticket ID if absent
case "$TITLE" in
  *"[$TICKET]"*|"$TICKET"*) : ;;
  *) TITLE="[$TICKET] $TITLE" ;;
esac

# Resolve requested reviewer usernames via glab-mr-assign's verifier
# (returns real usernames, comma-separated, or exits non-zero on any
# unresolved input)
REVIEWERS=$(glab-mr-verify-users brice sofiane)   # example: 2 first-name guesses
# → outputs: "reviewer-a,reviewer-b"

# Jira URL for the description (see jiraai for ${SITE} sourcing)
CFG=~/.local/share/jiraai/config.yaml
: "${SITE:=$(yq -r '.site' "$CFG")}"
JIRA_URL="https://$SITE/browse/$TICKET"

# Build description with the Jira URL as first-class link, not a
# buried comment. Preserve any user-authored body under "## What".
DESC=$(cat <<EOF
Related Jira: [$TICKET]($JIRA_URL)

## What
<one paragraph — what changes, from fix.md>

## Why
<one paragraph — from proof.md § Root cause>

## Rollout / rollback
<from fix.md § Blast radius>
EOF
)

glab mr create \
  --title "$TITLE" \
  --description "$DESC" \
  --assignee @me \
  ${REVIEWERS:+--reviewer "$REVIEWERS"} \
  --draft \
  --remove-source-branch

# Capture the returned MR IID and URL for downstream steps
MR_URL=$(glab mr view --output json | jq -r '.web_url')
MR_IID=$(glab mr view --output json | jq -r '.iid')
echo "Opened !$MR_IID — $MR_URL"
```

## Auto-merge arming — MANDATORY next step

Opening the MR without arming MWPS defeats the "push and forget"
model: the operator will have to babysit the pipeline and click
Merge manually. Immediately delegate to `glab-mr-automerge`:

```bash
# See glab-mr-automerge for the full recipe (draft-refusal,
# strategy detection, verification). One-liner:
glab-mr-automerge "$MR_IID"
```

Skip only when the operator explicitly passed `--no-automerge`
(e.g. release-day MRs that must NOT auto-merge on green). Log why.

## Reciprocal Jira remoteLink — MANDATORY next step

Opening the MR is half the wiring. Immediately delegate to
`jiraai-link` so the MR appears in the ticket's Development panel:

```bash
# See jiraai-link for the full recipe — this is the one-liner.
# Uses a stable globalId keyed off the MR URL for idempotency.
jiraai-link mr "$TICKET" "$MR_URL"
```

Without this step the ticket is orphaned — humans looking at the
Jira ticket cannot see the MR without opening GitLab.

## Verification gate — MANDATORY before reporting success

Before handing off, run the readiness check — the `glab-mr-ready`
skill formalises it, but the load-bearing subset here:

```bash
glab mr view "$MR_IID" --output json | jq '{
  title, draft, assignees:[.assignees[]?.username],
  reviewers:[.reviewers[]?.username]
}'
```

Expected: `title` starts with `[TICKET]`, contains exactly one
`Draft:` prefix (added by glab), `assignees` includes your username,
`reviewers` matches what you passed. **If any row is empty, act — do
not report success with empty state.**

## Skipping / non-default

- `--no-ticket`: no ticket ID in the branch AND operator opts out
  (e.g. a docs-only cleanup MR). Log why in the commit / description.
- `--no-reviewer`: solo repo where nobody else can review. Log why.
- `--ready` (skip draft): only when the branch is genuinely ready
  and the operator asked; default is `--draft` — you can always
  promote via `glab mr update <IID> --ready` after the readiness
  gate goes green.

## Composes with

- **glab-mr-automerge** — mandatory next step. Arms MWPS so the MR
  merges on green without further babysitting.
- **glab-push-flow** — the parent orchestrator. When `glab-mr-open`
  is invoked standalone (not from push-flow), it should HAND OFF to
  `glab-push-flow` after creation so the full lifecycle (ci-watch
  split + fail-fast poll + manual-triage on block) runs — do not
  re-implement those steps inline.
- **glab-mr-assign** — resolve first-name guesses → real usernames
  before `--reviewer`; add-vs-replace semantics.
- **glab-mr-title** — clean an already-broken title (`Draft: Draft:`,
  missing `[TICKET]`).
- **glab-mr-ready** — the readiness gate that follows creation.
- **jiraai-link** — reciprocal Jira remoteLink + optional MR-side
  note.
- **jiraai-mr** — full ticket-per-MR orchestrator when the branch
  does not yet have a tracking Jira Task in the dev project.
- **jira-fix** — support-ticket pipeline step 6/7 calls this skill.
- **mm-skills-gitlab-mr** — its `references/create-mr-workflow.md`
  covers the ManoMano house style for descriptions; read alongside.
