---
name: jira-review
description: MR review-cycle phase — pick reviewers from the eligible approver pool (`approval_state` + git-blame-on-changed-files heuristic), assign via `glab-mr-assign` (username-verified, `+`-add semantics), post an @mention Jira comment via `twg jira workitem comment create` on the support ticket ("MR !X ready for review, @<reviewer>"), then loop on review comments (`glab mr view` discussions) until approvals are green + no unresolved threads. Trigger on "request review", "ask for review", "get reviewers on the MR", "who should review", "@mention reviewer on jira", "review cycle for PLAT-1234", "address review comments then re-request". The `phase:review` step of the support-ticket bead DAG.
---

# jira-review — request review, address, get approvals green

The review-cycle phase between "MR opened" and "MR merged". Owns:
picking reviewers, posting the review request in the RIGHT places
(GitLab MR reviewer field + Jira @mention comment), and looping on
review feedback until the MR is approved.

## When to reach for it

- `glab-mr-open` returned an MR IID and its readiness gate is green
  on everything except approvals.
- `bd ready` surfaces a `phase:review` bead.
- User says "get X to review", "@mention Y on jira", "request review".

Do NOT reach for it before the MR exists (`glab-mr-open` first) or
before the pipeline is at least running (`glab-mr-ready`'s pipeline
row must not be red).

## Prerequisites

- Read `glab-mr-assign` (username verification + `+`-add semantics —
  the two footguns that broke earlier attempts).
- Read `jiraai` cookbook (ADF `mention` mark shape — how to @tag on
  Jira; needed when hand-rolling `curl` because `twg jira workitem
  comment create --body-format markdown` does not currently emit ADF
  `mention` marks — see step 3).
- Read `jiraai-review` (to know who last touched the ticket + any
  reviewer already suggested by the reporter).
- MR IID + `--repo <group/project>`; Jira ticket KEY.

## Step 1 — Build the reviewer candidate list

Two sources, unioned:

```bash
export GITLAB_HOST=<self-hosted-host>
REPO=<group/subgroup/project>
IID=<mr-iid>
TICKET=<PLAT-...>

PROJ_ID=$(glab api "projects/$(printf '%s' "$REPO" | jq -sRr @uri)" | jq -r .id)

# (a) Eligible approvers from the MR's approval rules — the pool
#     that CAN approve; the fix must earn a check from at least one.
approvers=$(glab api "projects/$PROJ_ID/merge_requests/$IID/approval_state" \
  | jq -r '.rules[]? | select(.approvals_required > 0) | .eligible_approvers[]?.username' \
  | sort -u)

# (b) Git-blame heuristic — who last touched the files this MR
#     changes. High signal; those people know the code.
changed=$(glab api "projects/$PROJ_ID/merge_requests/$IID/changes" \
  | jq -r '.changes[]?.new_path' | grep -v '^$' || true)
touchers=$(
  for f in $changed; do
    git -C "$repo_worktree" log -n 3 --format='%an' -- "$f" 2>/dev/null
  done | sort -u
)
# Map "Full Name" → username via glab_resolve_user (see glab-mr-assign)
```

Present the union to the operator (rank: intersection of both first),
never auto-pick. The operator's tribal knowledge beats the heuristic.

## Step 2 — Assign reviewers (glab side)

Delegate to `glab-mr-assign`. It verifies every name against
`glab api "users?username=…"` / `"users?search=…"`, refuses on 0
matches, surfaces ambiguity on multiple; uses `+username` so a
follow-up assign ADDS rather than clobbers.

```bash
# Never: glab mr update $IID --reviewer brice   # silent no-op
# Always via glab-mr-assign:
glab-mr-assign add-reviewer "$IID" reviewer-a   # verified, +-add
glab-mr-assign add-reviewer "$IID" reviewer-b
```

Verify the mutation landed:

```bash
glab mr view "$IID" --output json | jq '.reviewers[].username'
```

## Step 3 — @mention on the Jira ticket

The GitLab reviewer field pings the reviewer via GitLab notifications.
That's often invisible if the reviewer lives in Jira / Slack all day.
**Post an explicit @mention comment on the Jira ticket** via a raw
ADF `POST /issue/<KEY>/comment` (the `mention` mark is ADF-native and
markdown can't express it, so this one case bypasses `twg jira
workitem comment create` and hand-rolls curl) so the ticket's Development
panel + notifications tag them:

```bash
# Resolve reviewer accountId once (see jiraai cookbook for the ADF shape)
REV_ID=$(curl -sS -u "$AUTH" \
  "$ROOT/user/search?query=reviewer-a@corp.example" \
  | jq -r '.[0].accountId')
MR_URL="https://$GITLAB_HOST/$REPO/-/merge_requests/$IID"

BODY=$(jq -n --arg acct "$REV_ID" --arg url "$MR_URL" --arg iid "$IID" '{
  body: {
    type: "doc", version: 1, content: [{
      type: "paragraph", content: [
        { type: "mention", attrs: { id: $acct, text: "@Brice LALU" } },
        { type: "text", text: " could you review " },
        { type: "text", text: "!\($iid)",
          marks: [{ type: "link", attrs: { href: $url } }] },
        { type: "text", text: "? Draft while pipeline is running." }
      ]
    }]
  }
}')

curl -sS -u "$AUTH" -X POST "$ROOT/issue/$TICKET/comment" \
  -H 'Content-Type: application/json' -d "$BODY"
```

**One @mention per Jira comment** — a wall of mentions gets ignored.
If multiple reviewers, either one comment per person OR one comment
saying "@X / @Y please split the review — X on <area A>, Y on
<area B>".

**Ticket state**: DO NOT transition the Jira ticket to
"Waiting for customer" — that state means waiting on the reporter,
not colleagues. Ticket stays "In progress". PLAT has no
"Waiting for review" status; the review-request is the comment.

## Step 4 — Address comments (loop)

```bash
# Fetch the discussion threads
glab api "projects/$PROJ_ID/merge_requests/$IID/discussions" \
  | jq -r '.[] | select(.notes[0].resolvable == true and .notes[-1].resolved == false)
           | "\(.id)\t\(.notes[0].author.username)\t\(.notes[0].body[0:200])"'
```

For each unresolved thread:

1. Read the comment fully (`glab api .../discussions/<id>`).
2. Decide: address in code, push-back with rationale, or defer via
   a follow-up bead (`bd q "Follow-up: <thing>" --labels
   ticket:$TICKET,phase:followup`).
3. Push code changes on the same branch.
4. Resolve the thread server-side once the change lands OR reply
   with rationale via `glab mr note`.
5. `bd note $review_bead "Addressed <thread-id>: <one line>"`.

**`mm-skills-gitlab-mr`** owns the tone/tactics — see its
`respond-to-review.md` and `fix-review-comments.md` reference files.

## Step 5 — Close the bead when approvals are green

Close the `phase:review` bead when:

- `approval_state` shows every required rule as `approved: true`.
- `discussions` shows zero unresolved threads.
- Pipeline on the latest commit is `success` (or the ci-green bead
  is already closed).

Push-through condition: operator can force-close with a note if
consensus is verbal ("we agreed on Slack, no need for a formal
approval") — record the rationale.

## Anti-patterns

- **Assigning without verifying the username** — see `glab-mr-assign`
  for the exact failure. `--reviewer brice` silently fails.
- **@mentioning the whole team** — noise; nobody owns a mass
  mention. Pick a specific reviewer.
- **Transitioning the Jira ticket to "Waiting for customer" during
  review** — that field means "reporter action", not "colleague
  action". Wrong signal to the reporter.
- **Silently dismissing a review comment** — always reply with
  either the fix commit sha OR a rationale (`mm-skills-gitlab-mr`
  respond-to-review.md: "be honest — if a suggestion wasn't
  followed, explain why").
- **Posting the review request only on GitLab** — reviewers who live
  in Jira miss it. Post BOTH: `--reviewer` field + Jira @mention.

## Composes with

- **glab-mr-assign** — verified username adds.
- **glab-mr-ready** — the pre-req probe (pipeline / conflicts).
- **twg-jira** — `twg jira workitem comment create` for the everyday internal comment; hand-rolled ADF `curl` for the `mention`-mark case above.
- **mm-skills-gitlab-mr** — `respond-to-review.md`,
  `fix-review-comments.md` reference files own the tactics.
- **jira-merge** — the next phase after approvals green.
- **beads-flow** — dispatches this skill on `phase:review` beads.
