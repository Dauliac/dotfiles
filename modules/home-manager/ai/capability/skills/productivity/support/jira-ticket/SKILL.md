---
name: jira-ticket
description: Orchestrator for resolving a Jira support ticket end-to-end — sets up a per-ticket try dir, per-ticket beads, a per-ticket Dust conversation kept warm across every phase (explore → fix → answer), opens investigation TUIs in herdr, and drives the pipeline. **Dust is mandatory, not optional**: one conversation per ticket, reused via `--conversationId` at every step so the agent accumulates context (proof, fix, alternatives, prior art). Uses the `jiraai-*` skill family for all Jira Cloud REST v3 calls (auth, ADF, hierarchy, transitions) — never hand-roll `curl` when a `jiraai-*` primitive exists. Trigger on "resolve ticket X", "work on PLAT-1234", "handle this support ticket", a Jira URL, or when the user drops a ticket ID and asks for help. Composes with the `jira-explore`, `jira-fix`, and `jira-answer` step skills.
---

# jira-ticket — support ticket resolution orchestrator

**Statewright toggle** — If the operator's request contains
`--via-statewright` (or `--statewright`), STOP and delegate to the
declarative workflow: invoke `/sw:ticket <ticket-id>`. Do NOT run
the hardcoded pipeline below. If `--legacy` is present, run this
skill as documented. See the sibling skill
`jira-ticket-statewright-toggle` for the full routing table
(including the post-cutover default flip via
`~/.claude/workflows/.statewright-default`).

**IMPORTANT — humans on the other side.** The reporter is a real
teammate reading in Jira. They see **only** the final answer, not
the investigation. Keep the investigation invisible; the ticket-visible
output is the result plus the minimum facts / proofs the reporter needs
to verify or act. No process narration ("I looked at X, then checked
Y"), no filler, no "I hope this helps". If a line does not help them
act or verify, cut it. All notes / debugging / uncertainty / rabbit
holes go into the try dir (`proof.md`, `fix.md`, bead notes) — never
into a Jira comment.

Runs a single Jira / support ticket through a bead-tracked pipeline:

```text
setup:  try-dir + Dust seed + herdr tab + ticket.md (jiraai-review)
        + BEAD DAG (via beads-decompose) — one bead per phase, edges
        wired so `bd ready` gives the correct "what's next"

drive:  beads-flow loop dispatches per phase label:

  phase:set-capability  → jira-pick step 5 / twg jira workitem update --field 'Platform Capability=...'
  phase:explore         → jira-explore   → proof.md
  phase:fix-design      → jira-fix (1-5) → fix.md (needs user OK)
  phase:implement       → jira-fix (6) + glab-mr-open (verified reviewers, ticket-ID title, self-assign, jiraai-link)
  phase:ci-green        → glab-mr-ready (pipeline gate)
  phase:review          → jira-review (assign + @mention jira + comment loop)
  phase:merge           → jira-merge (readiness re-check + glab mr merge)
  phase:tag             → jira-merge (detect tag-management + tag)
  phase:deploy env:dev  → jira-deploy (fire dev deploy)
  phase:verify env:dev  → jira-monitor (pup/kubectl/aws/dig menu)
  phase:deploy env:stg  → jira-deploy
  phase:verify env:stg  → jira-monitor
  phase:deploy env:prd  → jira-deploy   ← MANUAL gate (blocking:human)
  phase:verify env:prd  → jira-monitor
  phase:answer          → jira-answer   → answer.md (needs user OK)
  phase:close           → jira-answer posts + transitions Done
                          (jira-answer refuses Done if capability empty)
```

Each phase is its own skill. This skill's job is the **setup** (dirs,
Dust, tab, bead DAG) and the **loop** (dispatch via `beads-flow`).

## When to reach for it

- The user names a ticket ID (`PLAT-4012`), pastes a Jira URL, or
  says "let's do a support ticket".
- The user says "on-call rotation", "support day", "triage this".
- Runs immediately after `jira-pick` — that skill hands off the
  claimed ticket key.

If the user says "grab a ticket from the queue" / "next incoming" /
"pick a support ticket", start with **`jira-pick`** (which claims
the ticket, moves it to On hold, assigns to the operator), then
this orchestrator takes over with the returned key.

Do NOT re-run setup for a ticket that already has its try dir + bead
+ Dust conversation ID — resume by `cd`-ing into the try dir and
continuing.

## Prerequisites

- Read **`references/dor-dod.md`** — the single per-phase DOR/DOD
  contract. Every phase skill consults it; `phase:close` verifies its
  DOR programmatically (MR merged, prod deploy success, capability
  set, no open rollback bead) before transitioning the ticket to Done.
  Auto-close never fires on trust of upstream bead state alone.
- Read the **`jiraai`** cookbook first — it owns auth (`${USER_EMAIL}`
  + sops token), custom-field IDs, ADF description format, transition
  IDs, and the `${SITE}` / `${JIRAAI_PROJECT}` placeholders every
  sibling skill consumes.
- `~/.local/share/jiraai/config.yaml` supplies defaults. Support
  tickets live in a **different project** from the dev-workflow
  default (`defaults.project`). Add a `defaults.support.project:
  <SUPPORT-KEY>` entry to the yaml (via the home-manager module
  that owns it) and override per-call:

  ```bash
  JIRAAI_PROJECT=$(yq -r '.defaults.support.project // .defaults.project' \
    ~/.local/share/jiraai/config.yaml)
  ```

  Every explore / fix / answer call then uses `$JIRAAI_PROJECT`
  instead of the dev default `XX`.

## Setup (one-time per ticket)

```bash
# 1. Per-day support root + per-ticket subdir
today=$(date +%F)
TRY_PATH="${TRY_PATH:-$HOME/src/tries}"
ticket=<TICKET-ID>              # e.g. PLAT-4012
ticket_dir="$TRY_PATH/${today}-support/${ticket}"
mkdir -p "$ticket_dir/.dust"
cd "$ticket_dir"

# 2. Bead DAG for the ticket — one bead per phase, deps wired.
#    Delegate the shape to beads-decompose (its "Support ticket" template
#    is the recipe below); it writes $ticket_dir/beads.json for downstream
#    skills to look up bead IDs by phase name.
#
#    Never one giant bead — `bd ready` needs discrete units to surface.
beads-decompose ticket "$ticket" > "$ticket_dir/beads.json"
# The DAG created:
#   root -+- set-capability
#         +- explore -> fix-design -> implement -+- ci-green -+
#                                                +- review ---+-> merge -> tag -> deploy-dev -> verify-dev
#                                                             \-> ... -> deploy-prod (MANUAL) -> verify-prod -> answer -> close
#   close depends on: answer + set-capability

# 3. Empty artifact files the step skills will fill
: > proof.md         # jira-explore writes here
: > fix.md           # jira-fix writes here
: > answer.md        # jira-answer writes here (STE100)

# 4. Deep briefing via jiraai-review — writes TWO files:
#    - ticket.md   : the root ticket (plain review — header + parent
#                    chain + children + links + remoteLinks + comments)
#    - related.md  : one-level walk on parent + subtasks + issuelinks;
#                    batch header pull + per-related remoteLinks table
#                    (cross-project links included — a PLAT ticket
#                    that "Blocks CARE-1442" surfaces CARE-1442's
#                    status + any in-flight MR).
jiraai-review "$ticket"        > ticket.md
jiraai-review "$ticket" --deep > related.md
# related.md is what feeds step 4b below AND jira-explore's prior-art
# search AND the beads DAG's phase:watch-related-mr entries.

# 4b. Extract MR URLs from related.md — for each unique one, prep a
#     watch-related-mr bead (see beads-decompose). This lets the
#     operator notice when an adjacent MR lands (potentially removing
#     the need for our own fix).
awk -F'\t' '/^https?:.*\/-\/merge_requests\// || $3 ~ /merge_requests/ {print $3}' \
  related.md | sort -u > related-mrs.txt
# beads-decompose reads related-mrs.txt and stamps one bead per URL,
# labelled ticket:$ticket,phase:watch-related-mr,blocking:human
# (human OK required — watching a repo you don't own is opt-in).

# 5. Transition the ticket to In Progress (optional — via twg jira workitem update --id "$KEY" --status 'In Progress').
#    Ask the user first if the ticket is not yours to grab.

# 6. One herdr tab per ticket — HARD INVARIANT.
#    After this step, the current herdr tab's label MUST equal
#    $ticket. Every phase skill and `beads-flow` re-verify this on
#    entry; the tab label is the pipeline's source of truth for
#    "which ticket is this shell working on". Rules:
#      (a) not in a herdr pane        -> HARD FAIL with instructions.
#                                        No silent skip — enforcement
#                                        depends on the tab label
#                                        being readable + persistent.
#      (b) current tab has no ticket  -> rename in place.
#      (c) tab already claims $ticket -> no-op (resume flow).
#      (d) tab claims a DIFFERENT     -> open a NEW tab labelled
#          ticket                        $ticket, cwd $ticket_dir,
#                                        focus it, and STOP this
#                                        setup script — the operator
#                                        (or the agent re-invoked in
#                                        the new tab) picks up from
#                                        step 1 with a clean shell.
if [ -z "$HERDR_TAB_ID" ]; then
  echo "ERROR: jira-ticket setup requires a herdr pane." >&2
  echo "  One-tab-per-ticket is enforced across the pipeline;" >&2
  echo "  every phase re-verifies the tab label against \$ticket." >&2
  echo "" >&2
  echo "  Fix: start herdr, then re-run inside a herdr pane:" >&2
  echo "    herdr                                              # attach/launch" >&2
  echo "    herdr tab create --label $ticket --cwd $ticket_dir --focus" >&2
  echo "" >&2
  echo "  Or rename an existing tab: herdr tab rename <tab-id> $ticket" >&2
  exit 2
fi

# Grep the raw `herdr tab get` output for any ticket-shaped token
# (e.g. PLAT-4012, GT-1234). Works whether the output is JSON or a
# human table — a substring match is enough to detect a claim.
current_claim=$(herdr tab get "$HERDR_TAB_ID" 2>/dev/null \
  | grep -oE '\b[A-Z][A-Z0-9]+-[0-9]+\b' | head -1)
case "$current_claim" in
  "")
    herdr tab rename "$HERDR_TAB_ID" "$ticket"
    ;;
  "$ticket")
    : # already ours, keep going
    ;;
  *)
    echo "Tab $HERDR_TAB_ID already claims $current_claim." >&2
    echo "Spawning a fresh tab for $ticket at $ticket_dir." >&2
    herdr tab create --label "$ticket" --cwd "$ticket_dir" --focus
    echo "Continue setup in the new tab. Aborting this run." >&2
    exit 0
    ;;
esac

# 7. Herdr split(s) for live investigation TUIs
#    (see tui-context / herdr-run for the split conventions)
```

## Tab-claim invariant (enforced end-to-end)

The tab label IS the pipeline's source of truth for "which ticket
this shell is working on". No persisted state file, no bead note,
no env var — the label itself. This is enforced at three points:

1. **`jira-ticket` setup step 6** — hard-fails outside herdr; renames
   or spawns a tab so `HERDR_TAB_ID`'s label equals `$ticket` before
   the script exits.
2. **`beads-flow` preflight** — every drive loop scoped with
   `--labels ticket:$ticket` re-reads the current tab label and
   aborts if it doesn't match. Runs on every fresh Claude session
   that resumes the DAG.
3. **Manual phase invocation** — if the operator (or agent) runs a
   `jira-*` phase skill directly instead of through `beads-flow`,
   they inherit the same check: the phase's opening step is
   `beads-flow drive --labels "ticket:$ticket"` in single-bead mode,
   which runs the preflight.

Resume in a fresh session: `cd $ticket_dir`, then
`beads-flow drive --labels "ticket:$ticket"`. The preflight
diagnoses tab drift immediately with an actionable error — do not
paper over it by re-running setup elsewhere; find the right tab
(`herdr tab list | grep $ticket`) and switch to it.

## Cloning a repo the ticket points at

Use `ghq` for the canonical clone, add a `git worktree` for the
ticket's branch, and **symlink the worktree into the try dir** so all
per-ticket state stays under `$ticket_dir`:

```bash
ghq get -p github.com/<owner>/<repo>            # canonical location
repo=$(ghq list -p -e <owner>/<repo>)
git -C "$repo" worktree add \
  "$repo/../worktrees/${ticket,,}" \
  <branch-name>
ln -s "$repo/../worktrees/${ticket,,}" "$ticket_dir/repo"
```

Never work inside the main clone's checkout for a ticket — the
worktree lets multiple tickets share one canonical clone without
stepping on each other.

## Dust conversation — mandatory, one per ticket, warm across all phases

Dust is not optional here. Every phase (`jira-explore`, `jira-fix`,
`jira-answer`) MUST call Dust through the **same** conversationId so
the Dust agent's context accumulates: at explore time it learns the
ticket body + repro; at fix time it already knows the root cause and
reviews the alternatives; at answer time it knows the whole story and
can vet the draft reply.

Seed the conversation at setup with the ticket body + goal — never with
"just the ticket key". Dust cannot see Jira, so paste what it needs:

```bash
dust_cid_file="$ticket_dir/.dust/conversation-id"

# Seed the conversation at setup with everything Dust needs to help
# through the whole pipeline. Do NOT rely on Dust to fetch the ticket.
if [ ! -s "$dust_cid_file" ]; then
  # Compose a rich seed message: ticket header + description + top
  # comments (from ticket.md, produced by jiraai-review at setup) +
  # the operator's own framing of the goal.
  seed=$(cat <<EOF
Support ticket $ticket. I will work on it through an explore → fix →
answer pipeline over the next hours or days, in this same Dust
conversation. Keep context between messages.

--- ticket header + comment thread (from jiraai-review) ---
$(cat ticket.md)

--- my goal ---
Investigate, propose a fix, and draft a short reply to the reporter.
I will feed you proof.md as I gather it, fix.md when I design the
fix, and answer.md before posting. Push back on shaky reasoning.
EOF
)
  out=$(dust chat --agent "dust" --message "$seed")
  printf '%s' "$out" | jq -r '.conversationId' > "$dust_cid_file"
  printf '%s\n' "$out" | jq -r '.agentAnswer' > "$ticket_dir/dust-log.md"
fi

# Every subsequent call in this ticket — use this exact form.
# Log the exchange to dust-log.md so the trail survives sessions.
dust_ask() {
  local msg="$1"
  local out
  out=$(dust chat --agent "dust" \
    --conversationId "$(cat "$dust_cid_file")" \
    --message "$msg")
  {
    echo ""
    echo "### $(date -Iseconds) — me"
    printf '%s\n' "$msg"
    echo ""
    echo "### $(date -Iseconds) — dust"
    printf '%s\n' "$out" | jq -r '.agentAnswer'
  } >> "$ticket_dir/dust-log.md"
  printf '%s\n' "$out" | jq -r '.agentAnswer'
}
```

**Rules of the warm session**:

- **One conversation per ticket**, never mix tickets — Dust will
  pollute contexts. Cross-reference sibling tickets in `bd note`
  instead.
- **Every phase MUST call Dust at least once** through
  `--conversationId` before finalizing its artifact:
  - `jira-explore` → asks for background / prior incidents / related
    teams and feeds proof.md findings back for validation.
  - `jira-fix` → gives Dust the proof + alternatives, asks for prior
    art / ADRs / gotchas / a second opinion on the chosen fix.
  - `jira-answer` → gives Dust the fix outcome + draft reply, asks
    for accuracy + tone check against the calibrated PLAT voice.
- **After each significant local finding, push it back to Dust** so
  the agent's memory of the ticket stays current. A stale Dust
  context that hasn't heard about a rediscovered root cause gives
  worse answers.
- **Log every exchange to `$ticket_dir/dust-log.md`** — cross-session
  humans (and future you) need the trail.
- **Never share the conversationId in Jira / MRs / Slack** — it is
  a session token to a workspace-scoped LLM.

See the `dust` skill for CLI mechanics.

## Pipeline — the beads-flow loop

Once setup is done, drive the DAG. This is a LOOP, not a linear
call — `beads-flow` picks the next ready bead, dispatches to the
matching phase skill, closes on success, and repeats until either
the DAG is complete or the next ready bead carries `blocking:human`.

```bash
beads-flow drive --labels "ticket:$ticket"
```

The routing table (phase label → skill) lives in the `beads-flow`
skill. For a support ticket, the effective order under normal
conditions is:

1. **set-capability** (independent; can also fire in parallel)
2. **explore** → `proof.md`
3. **fix-design** → `fix.md` — HUMAN GATE for user OK on design
4. **implement + open-mr** — HUMAN GATE for user OK on implementing
5. **ci-green** (delegates to `glab-mr-ready` for the pipeline probe)
6. **review** (assign + @mention on Jira via a raw ADF `mention`-mark curl + loop; `twg jira workitem comment create` for everything else)
7. **merge** (re-runs `glab-mr-ready` before firing `glab mr merge`)
8. **tag** (skip-closed if repo not tag-managed)
9. **deploy-dev / verify-dev**
10. **deploy-staging / verify-staging**
11. **deploy-prod / verify-prod** — HARD MANUAL GATE (`blocking:human`)
12. **answer** → `answer.md`
13. **close** (posts via `twg jira workitem comment create`, transitions Done via
    `twg jira workitem update --status Done`; refuses Done if `customfield_11907` is empty —
    the capability rule)

At every human gate, `beads-flow` stops and hands off to the
operator with a one-line "next" suggestion. All bead state, Dust
conversation, try dir, and `dust-log.md` survive session boundaries
— you can pick up any of these gates in a fresh Claude session by
running `beads-flow drive --labels "ticket:$ticket"` again.

**External-wait gates auto-resume** (ci-green, deploy, verify,
watch-related-mr, awaiting-reporter) — these arm **async-wait**
instead of blocking. The turn ends, Claude wakes on completion
(Bash bg exit / Monitor stdout / ScheduleWakeup deadline),
the wake-prompt re-enters `beads-flow`, and the DAG advances
without the operator prompting. `PushNotification` fires only on
actionable outcomes (pipeline failed, MR conflict, reporter
replied, 24h wait cap hit) — see `async-wait § Notification
policy` for the discipline.

## Hand-off shape

At any pause point, emit:

```text
Ticket:      $ticket ($JIRA_URL)
Try dir:     $ticket_dir
Bead DAG:    bd list --labels ticket:$ticket
Next ready:  <bead id> [phase:<name>] <title>
Blocked on:  <human decision required — one line>
Dust conv:   $(cat $ticket_dir/.dust/conversation-id)
Artifacts:   proof.md fix.md answer.md ticket.md dust-log.md \
             deploy.md verify-*.md beads.json
```

Never post to Jira, close the ticket, merge the MR, or fire a prod
deploy without explicit user OK at the corresponding gate.

## Investigation TUIs (open on demand)

Use the tool-specific watch skills — they open the right TUI in a
herdr split scoped to the ticket:

- **glab ci view** → `ci-watch` skill
- **k9s scoped to a namespace / selector** → `k8s-watch` skill
- **stu for an S3 bucket + prefix** → `s3-watch` skill
- **anything else** → `tui-context` skill

## Tool surface for the pipeline

Every phase can reach for these — the per-phase skills call them out
in context, but this is the full menu. Skim it once when you set the
ticket up so nothing important is forgotten:

| Domain | Read-only tool (explore) | Mutating tool (fix) |
| --- | --- | --- |
| Multi-account AWS / EKS / GitLab / Kafka Connect / Vault / JFrog | `ezsre commands`, `ezsre <group> list-*/all-*/search`, `ezsre what-about "…"` | `ezsre <group>` destructive verbs (get user OK first) |
| Single-account AWS | `aws … describe-*/list-*/get-*/filter-log-events`, `aws sts get-caller-identity` | `aws …` mutating verbs (get user OK first) |
| Kubernetes | `kubectl … get/describe/logs/events` (+ `explicit-cluster-context`) | `kubectl … apply/patch/rollout/delete` |
| GitLab MRs / pipelines | `glab mr view`, `glab ci view` (+ `ci-watch`) | `glab mr create --draft`, `glab ci retry` |
| Datadog | `pup logs aggregate`, `pup monitors get`, `pup metrics query` | `pup monitors mute/unmute` |
| Company knowledge | `dust chat --conversationId $(cat …)` | — |
| S3 | `aws s3 ls`, `s3-watch` (stu) | `aws s3 cp/sync --dryrun` first |

Discovery cheatsheet before writing any command:

- **Multi-account AWS / cross-cluster / fleet-wide?** → `ezsre
  commands` and `ezsre what-about "…"` before you hand-roll anything.
- **Single-account AWS?** → `aws --profile <p> --region <r> …` — never
  omit `--profile` or `--region`.
- **Kubernetes?** → `kubectl --context <ctx> -n <ns> …` — never rely
  on the shared current-context.
- **"Has this happened before?"** → `dust chat` against the ticket's
  persisted conversation ID.

## Multi-ticket days

Under the same `${today}-support` root, keep per-ticket subdirs
totally isolated. Each has its own bead, its own Dust conversation,
its own worktree, its own proof/fix/answer. Never share a Dust
conversation between two tickets — even if they look related, spawn
a fresh one and cross-reference in `bd note`.

## Composes with

- **Phase skills**: `jira-pick` (upstream, claim), `jira-explore`,
  `jira-fix`, `jira-review`, `jira-merge`, `jira-deploy`,
  `jira-monitor`, `jira-answer`.
- **Bead machinery**:
  - **beads-decompose** — builds the DAG at setup (the "Support
    ticket" template).
  - **beads-flow** — drives the DAG in a loop after setup, respecting
    `blocking:human` gates.
  - **beads** — the base CLI + discipline.
- **jiraai** (cookbook) and family — every Jira API call goes through
  a `jiraai-*` primitive:
  - **jiraai-review** — briefing dump into `ticket.md` at setup.
  - **twg-jira** — day-to-day Jira writes go through `twg jira workitem ...`:
    `query --jql "..."` to find related / duplicate tickets during explore;
    `update --status ...` for status transitions (On hold at claim, In Progress
    at implementation start, Done only after `answer` closes AND
    `set-capability` closed — the two-way gate); `comment create --body ... --body-format markdown`
    for internal status pings during the flow. Reviewer @mention on request-review is
    the one exception — the ADF `mention` mark isn't expressible in markdown, so
    `jira-review` step 3 hand-rolls a `curl` for that.
  - **jiraai-link** — attach the fix MR to the ticket (called by
    `glab-mr-open`).
  - **jiraai-mr** — full ticket-per-MR flow if the fix warrants its
    own tracking Task in the dev project.
- **glab-mr-***: `glab-mr-open` (create), `glab-mr-assign` (verified
  reviewer adds), `glab-mr-ready` (pipeline / approvals gate),
  `glab-mr-title` (canonicalisation).
- **dust**: `--conversationId` reuse, one per ticket, warm across all
  phases; logged to `$ticket_dir/dust-log.md`.
- **try**: the per-ticket workspace under
  `$TRY_PATH/$(date +%F)-support/$ticket/`.
- **ghq**: canonical repo clones fed into git worktrees, symlinked
  into the try dir.
- **herdr-layout**: spawn a workspace per ticket
  (`herdr workspace create --label "$TICKET"`) with one tab per phase
  (`explore`, `fix`, `review`, `deploy`) so the operator can jump
  between phases without losing the panes underneath.
- **herdr-find**: resume a mid-flight ticket across sessions —
  `herdr workspace list --json | jq --arg k "$TICKET" '.result.workspaces[] | select(.label==$k)'`
  locates the ticket's workspace ID and every pane inside it.
- **herdr / herdr-run / tui-context / ci-watch / k8s-watch / s3-watch**:
  the live investigation panes (foreground, operator-facing).
- **async-wait** — the invisible wake-back path for every long
  external condition in the DAG (ci-green, deploy, verify-baseline,
  watch-related-mr, awaiting-reporter). Each such bead gets a
  `watch:<kind>=<id>` note; on wake, Claude re-enters `beads-flow`
  and advances the DAG. `PushNotification` only on actionable
  outcomes.
- **explicit-cluster-context / aws**: mandatory scoping rules for
  kubectl / aws calls during explore / fix / verify.
- **pup**: Datadog CLI, used heavily by `jira-monitor` in verify
  phases.
- **ezsre**: multi-account SRE fan-out (AWS / EKS / GitLab / Kafka
  Connect / Vault / JFrog) — start with `ezsre commands` and `ezsre
  what-about "…"` before hand-rolling.
- **aws**: single-account AWS CLI — always with explicit `--profile`
  + `--region`.
- **kubectl**: scoped Kubernetes ops — always via
  `explicit-cluster-context`.
- **pup**: Datadog CLI for logs / metrics / monitors.
- **glab**: GitLab MRs / pipelines / issues.

## Gotchas

- `bd` uses the repo you `cd` into to find `.beads/` — create the
  bead from the actual project repo, not from the try dir, unless
  the try dir has been `bd init`ed.
- `TRY_PATH` may be empty in non-interactive shells — always
  `TRY_PATH="${TRY_PATH:-$HOME/src/tries}"` before scripting.
- Symlinking the worktree into the try dir works with tools that
  respect symlinks; a few build tools resolve them and get confused
  — if that happens, use a bind mount or `cd -P` awareness.
- Never post the draft answer or close the Jira ticket without user
  confirmation — those are external, hard-to-reverse actions.
