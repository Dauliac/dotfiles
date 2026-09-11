---
name: jira-fix
description: Ticket fix-design phase — take proof.md as input, design the smallest correct fix, capture it in fix.md, and optionally implement + open an MR. Uses `jiraai-mr` for the ticket-per-MR flow (dev-project ticket + branch + MR + reciprocal link), `twg jira workitem update --status ...` for status transitions on the support ticket, `twg jira workitem comment create` for internal status pings, `jiraai-link` for wiring the MR into the support ticket's Development panel. **After opening the MR, MANDATORY MR-readiness gate: check pipeline status, approval rules, assigned reviewers, blocking discussions, conflicts, title cleanliness — never report "opened, ready for your review" without that data** (compose with `mm-skills-gitlab-mr` + `ci-watch`; act to fix gaps, don't just report them). **Consults the warm Dust conversation as a design reviewer** — the same conversationId `jira-ticket` seeded and `jira-explore` fed with findings; Dust now knows the root cause and can point at prior fixes, ADRs, and gotchas from indexed sources. Trigger on "design a fix for the ticket", "how do we fix PLAT-1234", "propose a patch", "is the MR ready", "check MR pipeline", or as the second phase called by the `jira-ticket` orchestrator after `jira-explore`. Requires a proof.md with a root-cause hypothesis; refuse to proceed on speculation.
---

# jira-fix — design the fix, then implement (with user OK)

**IMPORTANT — design lives in fix.md, not in Jira.** The reporter
does not see alternatives-considered, rejected approaches, blast-radius
tables, or your reasoning chain. All of that goes into
`$ticket_dir/fix.md` and bead notes. What lands on the ticket is at
most an **internal status ping** via `twg jira workitem comment create` when the MR
opens ("MR !123 in review, ETA staging tomorrow" — one line, one
link) and the final reporter-facing answer that `jira-answer` posts
in the next phase. Nothing else.

Take a verified `proof.md` and turn it into a decision: what changes,
where, why, and what could go wrong. Optionally implement — but only
after the user OKs both the diagnosis and the fix shape.

## When to reach for it

- `jira-explore` produced a `proof.md` with a green repro and a
  root-cause hypothesis.
- The user asks "how do we fix this" for a ticket that has a proof
  document.

**Refuse to run** if `proof.md` is empty, has no repro, or lists only
"hypothesis: … (unverified)". Loop back to `jira-explore` — a fix on
speculation is how outages compound.

## Inputs

- `$ticket_dir/proof.md` (from `jira-explore`).
- `$ticket_dir/ticket.md` (from `jiraai-review` at setup) — has the
  team, capability, parent chain, existing links.
- Per-ticket bead and Dust conversation ID.
- The worktree symlinked at `$ticket_dir/repo` (if the fix is
  code-level).
- **Two Jira projects in play**:
  - The **support project** — where the reporter's ticket lives.
    Status transitions and answer comments go here (via
    `twg jira workitem update --status ...` / `twg jira workitem comment create` with `JIRAAI_PROJECT` set to
    `defaults.support.project`).
  - The **dev project** — where the tracking Task for the fix
    lives if the fix warrants its own dev ticket. `jiraai-mr`
    creates that Task and wires the MR to it (uses
    `defaults.project`).

## Output: `$ticket_dir/fix.md`

```markdown
# <TICKET-ID> — Fix Design

## Root cause (confirmed, not hypothesized)
<one paragraph, cross-linked to proof.md sections>

## Fix summary
<one paragraph — what changes, at which layer (code / config /
data / infra), scoped as narrowly as possible>

## Alternatives considered
- <A>: rejected because …
- <B>: rejected because …
- <chosen>: because …

## Change surface
- Repo: <name> (worktree at $ticket_dir/repo)
- Files: <file:line ranges>
- Config: <keys / envs / helm values>
- Data: <if any — migration, backfill, cleanup>
- Infra: <if any — helm chart, terraform, k8s resource>

## Patch / diff (or link)
```patch
… unified diff or link to a draft MR …
```

## Blast radius + rollout
- Affected users / requests / regions:
- Feature flag / config toggle:
- Rollout order: <e.g. dev → staging → canary → prod>
- Rollback: <exact command / MR to revert>

## Verification plan
- [ ] Unit / integration test added:
- [ ] Reproduces the bug pre-fix (see proof.md § Repro)
- [ ] Confirms fix post-fix
- [ ] Manual check: <steps>
- [ ] Metric / SLO to watch:
- [ ] Log-line / trace to expect:

## Risks
- <what could still break>
- <known edge cases the fix does not cover>

## Follow-ups (create beads)
- <thing worth fixing later but out of scope>
- <hardening / test-coverage gap>
```

## Method

1. **Re-read proof.md**. Anchor the fix in the confirmed root cause.
   If proof is thin, stop and loop back.
2. **Consult the warm Dust conversation — MANDATORY, twice.** Dust
   already knows the ticket and the root cause (fed by
   `jira-ticket` + `jira-explore`); use it here as a design reviewer,
   not a fresh oracle. Use the `dust_ask` helper defined in
   `jira-ticket` — it appends to `dust-log.md`.

   **Round 1 — prior art before designing:**

   ```bash
   dust_ask "For $ticket, root cause is now confirmed: <one line \
from proof.md>. Before I design a fix: (a) have you seen prior \
fixes for this exact pattern in indexed sources (Notion / GitHub / \
past incidents)? (b) any ADR or design doc I should read first? \
(c) any owner-team convention I'd be violating by fixing it in \
<layer>? Return links or 'no prior art'."
   ```

   **Round 2 — sanity-check the chosen fix before writing fix.md
   final version:**

   ```bash
   dust_ask "Draft fix design: <2-3 sentence summary of chosen \
approach>. Alternatives I rejected: <A>, <B>, and why. Blast \
radius: <one line>. Given everything you know about $ticket and \
the codebase indexed in the workspace: push back on this. Am I \
solving the symptom instead of the cause? Anything I'm ignoring? \
Any known gotcha with <chosen approach>?"
   ```

   Log Dust's answers in `fix.md § Alternatives considered` or
   `§ Risks` — do not swallow them silently.

3. **Enumerate alternatives** — always at least two before picking
   one. "The obvious fix" is a smell; write down the alternatives so
   the reader knows they were considered. Dust's Round-1 answer
   often surfaces a third alternative you did not think of.
4. **Design the narrowest fix that fully removes the root cause.**
   - No adjacent refactors.
   - No opportunistic cleanup.
   - No new abstractions "while we're here".
5. **Write fix.md** and share with the user for approval **before
   implementing**. Do not open an MR, do not push a branch, do not
   run migrations without explicit OK.
6. **After OK** — implement in `$ticket_dir/repo` (worktree).
   Follow the `commit-rationale` skill for the commit message body.
   For MR creation, **always use `glab-mr-open`** — it is the only
   sanctioned MR-creation path. It parses the ticket ID from the
   branch, embeds `[TICKET]` in the title, self-assigns `@me`,
   verifies each requested reviewer's username BEFORE calling glab
   (fixes the silent-no-op-on-first-name-guess bug), puts the Jira
   URL in the description (not just a comment), and delegates to
   `jiraai-link` for the reciprocal Jira remoteLink. For a
   ticket-per-MR flow with its own dev-project Task, layer
   `jiraai-mr` on top of `glab-mr-open`. Never call
   `glab mr create` directly — the raw call has known footguns
   (empty assignee, `Draft: Draft:` double prefix, unverified
   reviewer usernames, missing ticket ID in title).
7. **MR readiness gate — MANDATORY, before ANY handoff message.**
   Delegate to **`glab-mr-ready`** — it owns the three probes
   (`glab mr view --output json`, `.../approval_state`,
   `.../pipelines/<id>/jobs`), the fixed report shape, and the
   "act on reds, don't just report" contract (missing reviewer →
   `glab-mr-assign` with username verification; dirty title →
   `glab-mr-title`; failing pipeline → `glab job log` + fold into
   `fix.md § Risks`; running pipeline → hand off to `ci-watch`).
   Never emit "MR opened, over to you" without a green readiness
   report. The verbatim glab probes are documented below for
   reference; call `glab-mr-ready` in practice.

   ```bash
   export GITLAB_HOST=<self-hosted-host>   # e.g. git.corp.example
   MR_REPO="<group>/<subgroup>/<project>"  # exact glab --repo form
   MR_IID=<returned IID from glab mr create>

   # Header — state / draft / conflicts / discussions / reviewers
   glab mr view "$MR_IID" --repo "$MR_REPO" --output json | jq '{
     iid, title, state, draft, work_in_progress,
     detailed_merge_status, has_conflicts, blocking_discussions_resolved,
     reviewers: [.reviewers[]?.username],
     assignees: [.assignees[]?.username],
     user_notes_count,
     pipeline: {status: .head_pipeline.status,
                web_url: .head_pipeline.web_url}
   }'

   # Approval rules — WHO must approve, HOW MANY, and IS IT MET
   PROJECT_ID=$(glab api "projects/$(printf '%s' "$MR_REPO" | jq -sRr @uri)" | jq -r .id)
   glab api "projects/$PROJECT_ID/merge_requests/$MR_IID/approval_state" \
     | jq '{rules:[.rules[]? | {
         name, approvals_required, approved,
         eligible_approvers:[.eligible_approvers[]?.username]
       }]}'

   # Pipeline — jobs + status per stage
   PIPE_ID=$(glab api "projects/$PROJECT_ID/merge_requests/$MR_IID" | jq -r .head_pipeline.id)
   glab api "projects/$PROJECT_ID/pipelines/$PIPE_ID/jobs" \
     | jq -r '.[] | "\(.status)\t\(.stage)\t\(.name)"' | sort
   ```

   **Watch the pipeline live** (do NOT block the operator on a
   long build) — hand it off to `ci-watch` so the pane auto-closes
   when the pipeline reaches a terminal state:

   ```bash
   # ci-watch launches `glab ci view <branch>` in a herdr split with
   # an auto-close predicate on success/failed/canceled.
   # See the ci-watch skill for the exact herdr-tui invocation.
   ```

   **Readiness report — the ONLY acceptable handoff format**:

   ```text
   MR !$MR_IID — <one-line title>
     URL:                <mr.web_url>
     Title clean:        yes | NO (contains "Draft: Draft:" — clean it)
     Draft:              yes | no
     Merge status:       <detailed_merge_status>   (mergeable | draft_status | ci_still_running | ci_must_pass | ...)
     Conflicts:          no | YES
     Blocking threads:   0 | N (list)
     Pipeline:           success | running (X/Y jobs done) | failed (job <name>) | manual (gate <name>)
     Approvals:          M / N   (missing: <usernames>)
     Reviewers assigned: <usernames> | NONE — assign at least 1 from the eligible approvers
     Next action:        <one line: wait for pipeline / assign X / un-draft / fix conflict / …>
   ```

   Refuse to declare "ready for your review" until:
   - Title is free of double `Draft:` prefixes and matches conventional commits.
   - Pipeline is `success` (or the operator explicitly said "we ship
     from draft, don't wait for CI" — non-default).
   - At least one reviewer is assigned from the eligible approvers
     list — never leave `reviewers: []` for a merge-gated MR.
   - Blocking discussions resolved = true, conflicts = false.

   **If any row is red, act, don't just report.** Missing reviewer →
   `glab mr update $MR_IID --reviewer <username>`. Double `Draft:` →
   `glab mr update $MR_IID --title "<clean title>"`. Pipeline failed
   → read the failing job with `glab job log <job-id>` and fold the
   diagnosis into `fix.md § Risks`.

8. **Update Jira**:
   - Transition the support ticket state via **`twg jira workitem update --id "$ticket" --status 'In Progress'`**
     (at implementation start, then let `jira-answer` handle Done). twg resolves
     the right transition ID per issue type; see `jiraai` cookbook for raw IDs
     if you need a `curl` fallback.
   - Post an internal status ping via **`twg jira workitem comment create --issue-id "$ticket" --body "..." --body-format markdown`** when
     the MR opens (e.g. "MR !123 in review, ETA staging tomorrow").
     This is the *internal* comment; the reporter-facing close-out
     is `jira-answer` in the next phase.
9. **Update the bead**:

   ```bash
   bd note <id> "Fix designed: <one-line summary>. \
See $ticket_dir/fix.md. Awaiting user OK to implement." \
    # or after implementation:
   bd note <id> "Fix implemented in MR !<n>. \
Verification checklist status: <X/Y green>."
   ```

## Sizing the fix

- **Single-file, no data impact, no infra** → straight to
  implementation after user OK on fix.md.
- **Multi-file, config + code, or non-trivial refactor** → use the
  OpenSpec change flow (`/opsx:propose`) instead of a raw MR — see
  the project CLAUDE.md guidance. Fix.md becomes the seed for
  proposal.md.
- **Data migration or infra change** → require a rollback plan and
  a canary; don't skip the verification plan.

## Gotchas

- **Root cause vs symptom fix.** If the fix only masks the symptom
  (add a retry, catch an exception, raise a limit), say so
  explicitly under "Follow-ups" — don't call a symptom patch a
  root-cause fix.
- **Never `--force` push, `git reset --hard`, or `--no-verify`** in
  the worktree — the user's global rules and the project CLAUDE.md
  forbid it without explicit ask.
- **Don't open the MR to non-draft** without the verification plan
  actually run. `--draft` is cheap; reviewer surprise is not.
- **Don't post to Jira from this phase** — that's `jira-answer`.

## Composes with

- **jira-explore** (input: proof.md).
- **jira-answer** (next phase — reads fix.md to draft the reply).
- **jira-ticket** (parent orchestrator).
- **mm-skills-gitlab-mr** — owns the MR-readiness details:
  `prepare-for-review.md` (checklist before requesting review) and
  `summarize-mr-state.md` (status overview format). Load these
  when running step 7's readiness gate.
- **ci-watch** — opens the pipeline live in a herdr split with an
  auto-close predicate on terminal state; used by step 7.
- **glab** — the raw CLI wrapper the readiness gate calls (`glab mr
  view --output json`, `glab api ... /approval_state`, `glab api
  ... /pipelines/<id>/jobs`, `glab mr update --reviewer|--title`).
- **jiraai-mr** — ticket-per-MR flow when the fix warrants its own
  dev tracking Task.
- **jiraai-link** — wire the MR into the support ticket's
  Development panel (remoteLink + reciprocal `glab mr note`).
- **twg-jira** — `twg jira workitem update --status ...` for support-ticket
  status transitions; `twg jira workitem comment create` for internal status
  pings (distinct from the ASD-STE100 reporter reply that `jira-answer`
  produces); `twg jira workitem create` to spawn a follow-up Task if you
  discover out-of-scope work while designing the fix.
- **jiraai-commit-check** — auto-prefixes commits with `[KEY]`
  once the branch name embeds the dev Task's key (runs as a
  prepare-commit-msg hook).
- **commit-rationale**: shape the commit body when implementing.
- **hunk**: `hunk diff --watch` for reviewing the change before
  pushing.
- **herdr-layout**: when the fix opens an MR, name the CI pane
  (`herdr pane rename <id> "ci-$TICKET"`) so `herdr-find` can pick it
  up later without re-parsing terminal titles.
- **herdr-find**: locate the ticket's workspace / diff pane / CI pane
  on resume — filter panes by workspace label or pane rename.
- **beads**: capture follow-ups discovered while designing.
- **openspec**: for multi-file refactors, seed proposal.md from
  fix.md.
- **ezsre**: for fixes that fan out across accounts / clusters
  (`ezsre <group>` destructive verbs — cleanup, rollout,
  pause/resume, sync). Confirm the `destructive` / `reconciling`
  effect in `ezsre commands` and get user OK before running. Prefer
  `--aws-key=<env>` to scope; never run cross-account destructive
  ops with defaults.
- **aws**: single-account AWS mutations (`s3 cp/sync`, `ec2
  start/stop`, `lambda update-*`, `ecs update-service`, `logs
  create-*`, `secretsmanager …`). Always explicit `--profile` +
  `--region`. Run `aws sts get-caller-identity` right before every
  mutation and paste the output into the bead note. Try `--dryrun`
  on `s3 sync` first.
- **kubectl** + **explicit-cluster-context**: scoped Kubernetes
  mutations (`apply -f --server-side`, `patch`, `rollout restart`,
  `rollout undo`) — always with `--context` + `-n`.
- **pup**: mute a monitor for the duration of the fix rollout
  (`pup monitors mute --id <id> --duration <t>`); un-mute after the
  verification plan is green.
- **glab**: `glab mr create --fill --draft` to open the fix MR;
  promote to non-draft only after verification.
